codeunit 137153 "SCM Warehouse - Journal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Warehouse Journal] [SCM]
        isInitialized := false;
    end;

    var
        LocationWhite: Record Location;
        LocationSilver: Record Location;
        BasicLocation: Record Location;
        LocationSilver2: Record Location;
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryService: Codeunit "Library - Service";
        LibraryJob: Codeunit "Library - Job";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERM: Codeunit "Library - ERM";
        LibraryDimension: Codeunit "Library - Dimension";
        isInitialized: Boolean;
        RegisterJournalLines: Label 'Do you want to register the journal lines?';
        HandlingError: Label 'There is nothing to register.';
        LotNoEmptyError: Label 'Lot No. must have a value in Whse. Item Tracking Line';
        PhysicalInventoryError: Label 'Qty. to Handle (Base) in the item tracking assigned to the document line for item %1 is currently %2. It must be %3.\\Check the assignment for serial number %4, lot number %5, package number %6.', Comment = '%1 = Item No., %2 = Lot Specific Quantity, %3 = Total Quantity, %4 = Serial No., %5 = Lot No., %6 = Package No.';
        BinError: Label 'You cannot delete the Bin with Location Code = %1, Code = %2, because the Bin contains items.', Comment = '%1 = Location Code, %2 = Bin Code';
        BinContentError: Label 'You cannot delete this Bin Content, because the Bin Content contains items.';
        WarehouseLineMustNotExist: Label 'Warehouse Adjustment Lines must not exist.';
        JournalLinesRegistered: Label 'The journal lines were successfully registered';
        SingleExpirationDateError: Label 'Only one expiration date is allowed per lot number.';
        DirectedPutAwayAndPickErrorNewExpirationDate: Label 'Validation error for Field: New Expiration Date,  Message = ''You cannot change item tracking because the item is set up with warehouse tracking and location %1 is set up with Directed Put-away and Pick.';
        DirectedPutAwayAndPickSerialNo: Label 'Validation error for Field: Serial No.,  Message = ''You cannot change item tracking because it is created from warehouse entries.';
        ItemLedgerEntriesMustNotExist: Label 'Item Ledger Entries must not exist.';
        LocationCodeErrorOnPhysicalInventoryJournal: Label 'Validation error for Field: Location Code,  Message = ''You cannot change the Location Code because this item journal line is created from warehouse entries.';
        ItemReclassificationErrorWithNewLotNo: Label 'Validation error for Field: New Lot No.,  Message = ''You cannot change item tracking because the item is set up';
        ItemReclassificationErrorWithNewSerialNo: Label 'Validation error for Field: New Serial No.,  Message = ''You cannot change item tracking because the item is set';
        WarehouseLineMustExistErr: Label 'Warehouse Journal Line with Zone Code %1, Bin Code %2, Item No. %3 must be exist.';
        QtyCalculatedErr: Label 'Qty. Calculated is not correct.';
        BinContentErr: Label 'Bin Content should be deleted by registration Whse Journal Line';
        BinContentQuantityErr: Label 'Quantity (Base) available must not be less';
        UnitOfMeasureMustHaveValueErr: Label '%1 must have a value in Warehouse Journal Line', Comment = '%1=field name (Unit of Measure Code must have a value in Warehouse Journal Line)';
        TestFieldErrorErr: Label 'TestField';
        ItemJnlLineMustExistErr: Label 'Physical inventory journal line must be created';
        ItemNoErr: Label 'Item No. must have a value in Warehouse Journal Line';
        ReservationExistMsg: Label 'One or more reservation entries exist for the item';
        ExcessiveItemTrackingErr: Label 'More than one Item Tracking Line exists for the Item Journal Line.';
        AssignTracking: Option SerialNo,SelectTrackingEntries;
        TrackingAction: Option " ",VerifyTracking,AssignLotNo,AssistEdit,AssignSerialNo,AssitEditNewSerialNoExpDate,AssignMultipleLotNo,MultipleExpirationDate,SelectEntries,AssitEditSerialNoAndRemoveExpDate,EditSerialNo,AssitEditLotNo,AssitEditNewLotNoExpDate,AssignSerialAndLot,AssignNewSerialAndLotNo,SelectEntriesWithLot,SelectEntriesWithNewSerialNo,SetNewLotNoWithQty;
        UserIsNotWhseEmployeeErr: Label 'You must first set up user %1 as a warehouse employee.';
        UserIsNotWhseEmployeeAtWMSLocationErr: Label 'You must first set up user %1 as a warehouse employee at a location with the Bin Mandatory setting.';
        DefaultLocationNotDirectedPutawayPickErr: Label 'You must set up a default location with the Directed Put-away and Pick setting and assign it to user %1.';
        WrongWhseJournalBatchOpenedErr: Label 'Wrong warehouse journal batch has been opened.';
        WrongBinCreationWkshOpenedErr: Label 'Wrong bin creation worksheet has been opened.';
        BinMustNotBeAdjustmentErr: Label 'Adjustment Bin must not be Yes in Bin';
        ItemTrackingMode: Option "Lot No","Serial No","Lot No. Reclassification";
        WrongWhseJournalBatchErr: Label 'Wrong warehouse journal batch name is added to the filter of a line.';
        WrongLocationCodeErr: Label 'Wrong location name is added to the filter of a line.';
        WhseJournalBatchDefaultNameTxt: Label 'DEFAULT';
        DirectedWhseLocationErr: Label 'You cannot use %1 %2 because it is set up with %3.\Adjustments to this location must therefore be made in a Warehouse Item Journal.', Comment = '%1: Location Table Caption, %2: Location Code, %3: Location Field Caption';
        ConfirmWhenExitingQst: Label 'One or more lines have tracking specified, but Quantity (Base) is zero. If you continue, data on these lines will be lost. Do you want to close the page?';
        OnlyOneWarehouseJournalLineShouldBeCreatedErr: Label 'Only One Warehouse Jorunal Line should be created.';
        SerialNoMustMatchErr: Label 'Serial No. must match.';
        LotNoMustMatchErr: Label 'Lot No. must match.';
        LotNoMustBeBlankErr: Label 'Lot No. must be blank.';
        SerialNoMustBeBlankErr: Label 'Serial No. must be blank.';

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PostWhseItemJournalWithoutLotNoOnItemTrackingLine()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        // Setup: Create Warehouse Journal Line with Tracking Lines.
        Initialize();
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(true);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        CreateItemWithTrackingCode(Item, false, true);
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2), true);  // Use random Quantity.

        // Exercise: Register Warehouse Journal Line.
        LibraryVariableStorage.Enqueue(RegisterJournalLines);  // RegisterJournalLines used in ConfirmHandler.
        asserterror LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, false);

        // Verify: Error Message Missing Lot No..
        Assert.IsTrue(StrPos(GetLastErrorText, LotNoEmptyError) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure PostPartialPurchaseOrderWithItemTrackingLine()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Bin: Record Bin;
    begin
        // Setup : Create Purchase Order with Partial Receive and Invoice.
        Initialize();
        CreateItemWithTrackingCode(Item, false, true);
        LibraryWarehouse.FindBin(Bin, LocationSilver.Code, '', 1);  // Use 1 for Bin Index.
        CreatePurchaseOrderForPartialShipmentAndInvoice(PurchaseHeader, PurchaseLine, Item."No.", LocationSilver.Code, Bin.Code);

        // Exercise: Post Purchase Order.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: Warehouse Entry.
        VerifyWarehouseEntry(PurchaseLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseItemJournalWithoutQuantity()
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        Initialize();
        PostWarehouseJournalLine(WarehouseJournalTemplate.Type::Item);  // Warehouse Item Journal.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhsePhysicalInventoryJournalWithoutQuantity()
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        Initialize();
        PostWarehouseJournalLine(WarehouseJournalTemplate.Type::"Physical Inventory");  // Warehouse Physical Inventory.
    end;

    local procedure PostWarehouseJournalLine(Type: Enum "Warehouse Journal Template Type")
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Setup: Create Warehouse Journal Line.
        CreateItem(Item, '');
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, Type, Item."No.", 0, false);  // Value Zero Important for test.

        // Exercise: Register Warehouse Journal line.
        LibraryVariableStorage.Enqueue(RegisterJournalLines);  // RegisterJournalLines used in ConfirmHandler.
        LibraryVariableStorage.Enqueue(HandlingError);  // RegisterJournalLines used in MessageHandler.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, false);

        // Verify: Verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PostWhseReclassificationJournalWithoutQuantity()
    var
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        BinContent: Record "Bin Content";
    begin
        // Setup: Create Warehouse Journal Line. Create Bin Content.
        Initialize();
        CreateItem(Item, '');
        FindBin(Bin, LocationWhite.Code, true);  // Find Bin for From Bin Code.
        FindBin(Bin2, LocationWhite.Code, false);  // Find Bin for To Bin Code.
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin2."Location Code", Bin2."Zone Code", Bin2.Code, Item."No.", '', Item."Base Unit of Measure");
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Reclassification, LocationWhite.Code);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, '', '',
          WarehouseJournalLine."Entry Type"::Movement, Item."No.", 0);  // Value Zero Important for test.
        ModifyWhseJournalLineForReclass(WarehouseJournalLine, Bin, Bin2);

        // Exercise: Register Warehouse Journal line.
        LibraryVariableStorage.Enqueue(RegisterJournalLines);  // RegisterJournalLines used in ConfirmHandler.
        LibraryVariableStorage.Enqueue(HandlingError);  // RegisterJournalLines used in MessageHandler.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, false);

        // Verify: Verification done in ConfirmHandler.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhseItemJournalWithSerialAndLotNoWithoutLotSpecific()
    begin
        Initialize();
        RegisterWhseItemJournalWithItemTracking(false);  // Register Warehouse Journal Line With Serial and Lot No. without Lot Specific in Item Tracking Code.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhseItemJournalWithSerialAndLotNo()
    begin
        Initialize();
        RegisterWhseItemJournalWithItemTracking(true);  // Register Warehouse Journal Line with Serial and Lot No.
    end;

    local procedure RegisterWhseItemJournalWithItemTracking(Lot: Boolean)
    var
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Setup: Create Warehouse Journal Line with Tracking Lines.
        LibraryVariableStorage.Enqueue(TrackingAction);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(true);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        CreateItemWithTrackingCode(Item, true, Lot);
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", LibraryRandom.RandInt(10), true);

        // Exercise: Register Warehouse Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, true);

        // Verify: Verify Serial No. and Lot No. in Warehouse Entries.
        VerifyWarehouseEntriesForLotAndSerialNo(WarehouseJournalLine, WarehouseEntry."Entry Type"::"Positive Adjmt.", 1, Lot);  // Verify Serial Quantity.
        VerifyWarehouseEntriesForLotAndSerialNo(WarehouseJournalLine, WarehouseEntry."Entry Type"::"Negative Adjmt.", -1, Lot); // Verify Serial Quantity.
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler,ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateAdjustmentWithSerialAndLotNo()
    var
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Create Warehouse Journal Line with Tracking Lines, Assign Serial No. and Lot No. on Warehouse Journal Line and Register.
        Initialize();
        LibraryVariableStorage.Enqueue(TrackingAction);
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(true);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(TrackingAction::VerifyTracking);  // TrackingAction used in ItemTrackingLinesPageHandler.
        CreateItemWithTrackingCode(Item, true, true);
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", LibraryRandom.RandIntInRange(6, 9), true);  // Value Required Creating multiple Tracking Lines.
        LibraryVariableStorage.Enqueue(WarehouseJournalLine.Quantity);  // Quantity used in ItemTrackingLinesPageHandler.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, true);

        // Exercise: Calculate Warehouse Adjustment. Open Item Tracking Line Page.
        CalculateWhseAdjustment(ItemJournalBatch, Item);
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Item."No.");
        ItemJournalLine.OpenItemTrackingLines(false);

        // Verify: Warehouse Adjustment Line on Item Journal. Verify Item Tracking Line on Item Tracking Page done in ItemTrackingLinesPageHandler.
        VerifyWarehouseAdjustmentLine(ItemJournalBatch, Item."No.", WarehouseJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure CalculatePhysicalInventoryAndPost()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        LotNo: Variant;
    begin
        // Setup: Update Bin Quantity by posting Item Journal Lines with Item Tracking.
        Initialize();
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateItemWithTrackingCode(Item, false, true);
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item, false);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // TrackingAction used in ItemTrackingLinesPageHandler.
        CreateItemJournalLineWithItemTracking(ItemJournalLine, ItemJournalBatch, Bin, Item."No.", LibraryRandom.RandDec(100, 2), true);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // TrackingAction used in ItemTrackingLinesPageHandler.
        CreateItemJournalLineWithItemTracking(ItemJournalLine, ItemJournalBatch, Bin, Item."No.", ItemJournalLine.Quantity, true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        LibraryVariableStorage.Enqueue(TrackingAction::AssistEdit);  // TrackingAction used in ItemTrackingLinesPageHandler.

        // Exercise: Create and Post Physical Inventory Journal.
        asserterror CreateAndPostPhysicalInventory(Item."No.", LocationSilver.Code, Bin.Code, true);

        // Verify: Error Message for Total Quantity more than Lot Specific Quantity.
        LibraryVariableStorage.Dequeue(LotNo);  // Dequeue LotNo Used in ItemTrackingLinesPageHandler.
        Assert.ExpectedError(
          StrSubstNo(
            PhysicalInventoryError,
            Item."No.", ItemJournalLine.Quantity, ItemJournalLine.Quantity * 2, '', LotNo, ''));  // Total Physical Quantity is Twice the Lot Specific Quantity.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteBinAfterPostingItemJournalLineAndVerifyError()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CreateItem(Item, '');
        CreateAndPostItemJournalLineWithBin(ItemJournalLine, Item."No.", Item."Base Unit of Measure");

        // Exercise: Delete Bin.
        asserterror DeleteBin(ItemJournalLine."Location Code", ItemJournalLine."Bin Code");

        // Verify: Verify Error while Deleting Bin.
        Assert.ExpectedError(StrSubstNo(BinError, LocationSilver.Code, ItemJournalLine."Bin Code"));

        // Exercise: Delete Bin Content.
        asserterror DeleteBinContent(ItemJournalLine."Location Code", ItemJournalLine."Bin Code", ItemJournalLine."Item No.", '');

        // Verify: Verify Error while Deleting Bin Content.
        Assert.ExpectedError(BinContentError);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteBinAfterPostingPhysicalInventoryJournal()
    var
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        CreateItem(Item, '');
        CreateAndPostItemJournalLineWithBin(ItemJournalLine, Item."No.", Item."Base Unit of Measure");

        // Exercise: Create and Post Physical Inventory.
        CreateAndPostPhysicalInventory(ItemJournalLine."Item No.", LocationSilver.Code, ItemJournalLine."Bin Code", false);

        // Verify: Verify Bin is deleted after Posting Physical Inventory.
        DeleteBin(ItemJournalLine."Location Code", ItemJournalLine."Bin Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisterWarehouseItemJournalLineWithBlockedItem()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // Setup: Create Warehouse Journal Line.
        Initialize();
        CreateBlockedItem(Item);
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", LibraryRandom.RandDec(100, 2), false);

        // Exercise: Register Warehouse Item Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, true);

        // Verify: Verify Warehouse Entry After Register Warehouse Item Journal Line for Blocked Item.
        VerifyWarehouseEntryWithBlockedItem(
          WarehouseJournalLine, WarehouseEntry."Entry Type"::"Positive Adjmt.", WarehouseJournalLine.Quantity);
        VerifyWarehouseEntryWithBlockedItem(
          WarehouseJournalLine, WarehouseEntry."Entry Type"::"Negative Adjmt.", -WarehouseJournalLine.Quantity);
    end;

    [Test]
    procedure GetBinContentForLocationNotAllowed()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Bin: Record Bin;
        ItemNo: Code[20];
    begin
        //Setup: Create Warehouse Journal Line with Bin and Post it.
        Initialize();

        ItemNo := LibraryInventory.CreateItemNo();
        FindBin(Bin, LocationWhite.Code, true);

        CreateItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, true);

        CreateWarehouseJournalLine(
         WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2), false);

        LibraryWarehouse.PostWhseJournalLine(
         WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code);

        // Exercise: Get Bin Content for Location with Directed Put-away and Pick. Error must be thrown because of Location with Directed Put-away and Pick.
        asserterror GetBinContentFromItemJournalLine(ItemJournalBatch, LocationWhite.Code, Bin.Code, ItemNo);

        Assert.ExpectedError(StrSubstNo(DirectedWhseLocationErr, LocationWhite.TableCaption(), LocationWhite.Code, LocationWhite.FieldCaption("Directed Put-away and Pick")));
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

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure CalculateWarehouseAdjustmentWithMultipleUOM()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        ItemJournalBatch: Record "Item Journal Batch";
        Quantity: Decimal;
    begin
        // Setup: Create Warehouse Journal Line with Tracking Lines, Assign Lot No. on Warehouse Journal Line and Register.
        Initialize();
        CreateItemWithTrackingCode(Item, false, true);
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        FindBin(Bin, LocationWhite.Code, true);
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndUpdateWarehouseJournalLinesWithItemTrackingAndMultipleUOM(
          WarehouseJournalLine, Bin, Item."No.", ItemUnitOfMeasure.Code, Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, true);
        CalculateWhseAdjustment(ItemJournalBatch, Item);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        CreateAndUpdateWarehouseJournalLinesWithItemTrackingAndMultipleUOM(
          WarehouseJournalLine, Bin, Item."No.", ItemUnitOfMeasure.Code, Quantity + 10);  // Higher Quantity required than above posted Item Journal Lines.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, true);

        // Exercise: Calculate Warehouse Adjustment.
        CalculateWhseAdjustment(ItemJournalBatch, Item);

        // Verify: Warehouse Adjustment Line on Item Journal.
        Assert.IsFalse(VerifyWhseAdjustmentLinesnotExist(ItemJournalBatch, Item."No.", Quantity), WarehouseLineMustNotExist);
        VerifyWhseAdjustmentLinesWithMultipleUnitOfMeasure(
          ItemJournalBatch, Item."No.", Item."Base Unit of Measure", WarehouseJournalLine.Quantity);
        VerifyWhseAdjustmentLinesWithMultipleUnitOfMeasure(
          ItemJournalBatch, Item."No.", ItemUnitOfMeasure.Code, WarehouseJournalLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure PostPhysicalInventoryJournalForCountingPeriodWithoutQuantityDifference()
    begin
        Initialize();
        PostPhysicalInventoryJournalForCountingPeriod(false);  // Post Warehouse Journal without Difference in Quantity.
    end;

    [Test]
    [HandlerFunctions('PhysicalInventoryItemSelectionHandler,CalculatePhysicalInventoryCountingHandler')]
    [Scope('OnPrem')]
    procedure PostPhysicalInventoryJournalForCountingPeriodWithQuantityDifference()
    begin
        Initialize();
        PostPhysicalInventoryJournalForCountingPeriod(true);  // Post Warehouse Journal with Difference in Quantity.
    end;

    local procedure PostPhysicalInventoryJournalForCountingPeriod(QuantityDifference: Boolean)
    var
        Bin: Record Bin;
        Item: Record Item;
        PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalLine2: Record "Warehouse Journal Line";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseEntry: Record "Warehouse Entry";
        PhysInvtCountManagement: Codeunit "Phys. Invt. Count.-Management";
        NextCountingStartDate: Date;
        NextCountingEndDate: Date;
    begin
        // Setup: Create Item with Physical Inventory Counting Period. Create and register Warehouse Journal Line. Run Calculate Counting Period on Warehouse Physical Inventory Journal.
        CreateItemWithPhysicalInventoryCountingPeriod(Item, PhysInvtCountingPeriod);
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", LibraryRandom.RandInt(10), false);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, true);
        LibraryVariableStorage.Enqueue(Item."No.");  // ItemNo used in PhysicalInventoryItemSelectionHandler.
        PhysInvtCountManagement.CalcPeriod(
          Item."Last Counting Period Update", NextCountingStartDate, NextCountingEndDate,
          PhysInvtCountingPeriod."Count Frequency per Year");
        LibraryVariableStorage.Enqueue(NextCountingStartDate);  // NextCountingStartDate used in PhysicalInventoryItemSelectionHandler.
        LibraryVariableStorage.Enqueue(NextCountingEndDate);  // NextCountingEndDate used in PhysicalInventoryItemSelectionHandler.
        RunCalculateCountingPeriodOnWarehousePhysicalInventoryJournal(WarehouseJournalLine2, LocationWhite.Code);
        FindWarehouseJournalLine(WarehouseJournalLine2, Item."No.");
        if QuantityDifference then
            UpdateQuantityPhysicalInventoryOnWarehouseJournalLine(
              WarehouseJournalLine2, WarehouseJournalLine2."Qty. (Phys. Inventory)" / 2);

        // Exercise: Post Warehouse Physical Inventory Journal for Calculated Counting Period.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine2."Journal Template Name", WarehouseJournalLine2."Journal Batch Name", LocationWhite.Code, true);

        // Verify: Verify Warehouse Entries.
        VerifyWarehouseEntryForCoutingPeriod(
          WarehouseJournalLine2, WarehouseEntry."Entry Type"::"Positive Adjmt.", -WarehouseJournalLine2.Quantity);
        VerifyWarehouseEntryForCoutingPeriod(
          WarehouseJournalLine2, WarehouseEntry."Entry Type"::"Negative Adjmt.", WarehouseJournalLine2.Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryOnWhsePhysicalInventoryJournalWithDifferentZoneAndItemVariant()
    var
        Item: Record Item;
        Bin: Record Bin;
        Bin2: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalLine2: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        ItemVariant: Record "Item Variant";
    begin
        // Setup: Create Item with Variant. Create Warehouse Journal line with Bin and Item Variant. Calculate and Post Warehouse Adjustment.
        Initialize();
        CreateItem(Item, '');
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        FindBin(Bin, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        CreateAndUpdateWarehouseJournalLineWithBin(
          WarehouseJournalLine, WarehouseJournalBatch, Bin, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        FindBin(Bin2, LocationWhite.Code, false);  // Select Next Zone Code.
        CreateAndUpdateWarehouseJournalLineWithBin(
          WarehouseJournalLine, WarehouseJournalBatch, Bin2, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        RegisterWarehouseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code);
        CalculateAndPostWhseAdjustment(Item);

        // Exercise: Calculate Inventory on Warehouse Physical Journal.
        RunWarehouseCalculateInventory(WarehouseJournalLine2, Bin2."Zone Code", Bin2."Location Code", '');

        // Verify: Warehouse Physical Journal Line.
        VerifyWarehousePhysicalJournalLine(WarehouseJournalLine2, Bin2, Item."No.");
        Assert.IsFalse(
          VerifyWarehousePhysicalJournalLineExist(WarehouseJournalLine2, Bin."Zone Code", Item."No."), WarehouseLineMustNotExist);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryOnPhysicalInventoryJournalWithDifferentLocation()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        LocationCode: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Create and Post Item Journal Line and Warehouse Physical Inventory Journal with Different location Code. Calculate and Post Warehouse Adjustment.
        Initialize();
        CreateItem(Item, '');
        FindBin(Bin, LocationWhite.Code, true);
        CreateAndPostItemJournalLineWithBin(ItemJournalLine, Item."No.", Item."Base Unit of Measure");
        LocationCode := ItemJournalLine."Location Code";
        Quantity := ItemJournalLine.Quantity;
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        CreateAndUpdateWarehouseJournalLineWithBin(
          WarehouseJournalLine, WarehouseJournalBatch, Bin, Item."No.", '', Item."Base Unit of Measure");
        RegisterWarehouseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code);
        CalculateAndPostWhseAdjustment(Item);

        // Exercise: Calculate Inventory on Physical Journal.
        RunReportCalculateInventory(ItemJournalLine, Item."No.", '', '', false);

        // Verify: Physical Inventory Journal Line is Created for both the location.
        VerifyPhysicalInventoryJournal(ItemJournalLine, Item."No.", Bin."Location Code", WarehouseJournalLine.Quantity);
        VerifyPhysicalInventoryJournal(ItemJournalLine, Item."No.", LocationCode, Quantity);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryOnPhysicalInventoryJournalMultipleUOM()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        ItemVariant: Record "Item Variant";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Create and Post Warehouse Physical Inventory Journal with Multiple Unit of Measure and Item Variant. Calculate and Post Warehouse Adjustment.
        Initialize();
        CreateItem(Item, '');
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.");
        FindBin(Bin, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        CreateAndUpdateWarehouseJournalLineWithBin(
          WarehouseJournalLine, WarehouseJournalBatch, Bin, Item."No.", ItemVariant.Code, Item."Base Unit of Measure");
        Quantity := WarehouseJournalLine.Quantity;
        CreateAndUpdateWarehouseJournalLineWithBin(
          WarehouseJournalLine, WarehouseJournalBatch, Bin, Item."No.", ItemVariant.Code, ItemUnitOfMeasure.Code);
        RegisterWarehouseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code);
        CalculateAndPostWhseAdjustment(Item);

        // Exercise: Calculate Inventory on Physical Journal.
        RunReportCalculateInventory(ItemJournalLine, '', Bin."Location Code", '', false);

        // Verify: Physical Inventory Journal Line is Created.
        VerifyPhysicalInventoryJournal(
          ItemJournalLine, Item."No.", Bin."Location Code",
          Quantity + WarehouseJournalLine.Quantity * ItemUnitOfMeasure."Qty. per Unit of Measure");  // Verify total base Quantity.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,QuantityToCreatePageHandler,WhseItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure RegisterReclassificationWithExpirationDate()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        SerialNo: Variant;
        NewSerialNo: Variant;
    begin
        // Setup: Create and Post Warehouse Receipt and Register Put Away.
        Initialize();
        PostWarehouseReceiptAndRegisterPutAwayForSerialNo(RegisteredWhseActivityLine, '', LibraryRandom.RandInt(10), false);

        // Exercise: Create Warehouse Reclassification Journal.
        LibraryVariableStorage.Enqueue(TrackingAction::AssitEditNewSerialNoExpDate);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        CreateWarehouseReclassificationJournalAndRegister(RegisteredWhseActivityLine, '');

        // Verify: Item Ledger Entry for New Expiration and Serial No.
        LibraryVariableStorage.Dequeue(SerialNo);
        LibraryVariableStorage.Dequeue(NewSerialNo);
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, RegisteredWhseActivityLine."Item No.", RegisteredWhseActivityLine."Location Code",
          false, SerialNo, '', 0D, -1);  // Used 0D for Blank Date and -1 for Quantity.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, RegisteredWhseActivityLine."Item No.", RegisteredWhseActivityLine."Location Code", true,
          NewSerialNo, '', WorkDate(), 1);  // Used 1 for Quantity.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure RegisterReclassificationWithMultipleLotNoAndDifferentExpirationDate()
    begin
        Initialize();
        RegisterReclassificationJournal(false);  // Register Warehouse Reclassification Journal with Multiple Lot and Different Expiration Date.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure RegisterReclassificationWithMultipleExpirationDate()
    begin
        Initialize();
        RegisterReclassificationJournal(true);  // Register Warehouse Reclassification Journal with Multiple Expiration Date on Lot No.
    end;

    local procedure RegisterReclassificationJournal(MultipleExpirationDate: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        TrackingSpec: Record "Tracking Specification";
        DequeueVariable: Variant;
        LotNo: Code[50];
    begin
        // Setup: Create and Post Warehouse Receipt.
        CreateItemWithTrackingCode(Item, false, true);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignMultipleLotNo);  // TrackingAction used in ItemTrackingLinesPageHandler.
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, '', Item."No.", true, LibraryRandom.RandInt(5));
        LibraryVariableStorage.Dequeue(DequeueVariable);
        LotNo := DequeueVariable;
        LibraryVariableStorage.Dequeue(DequeueVariable);
        CreateAndPostWarehouseReceipt(WarehouseReceiptLine, PurchaseHeader, '', false);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");

        if MultipleExpirationDate then
            LibraryVariableStorage.Enqueue(TrackingAction::MultipleExpirationDate)
        else
            LibraryVariableStorage.Enqueue(TrackingAction::AssignMultipleLotNo);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        if not MultipleExpirationDate then
            LibraryVariableStorage.Enqueue(LotNo);  // LotNo used in WhseItemTrackingLinesHandler.
        FindRegisteredPutAway(RegisteredWhseActivityLine, Item."No.");

        // Exercise: Create Warehouse Reclassification Journal and Register.
        asserterror CreateWarehouseReclassificationJournalAndRegister(RegisteredWhseActivityLine, '');

        // Verify: Expiration Date Error.
        if MultipleExpirationDate then
            Assert.IsTrue(StrPos(GetLastErrorText, SingleExpirationDateError) > 0, GetLastErrorText)
        else
            Assert.ExpectedTestFieldError(TrackingSpec.FieldCaption("New Expiration Date"), '''');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,QuantityToCreatePageHandler,WhseItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure RegisterReclassificationAfterRemovingExpirationDate()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SerialNo: Variant;
    begin
        // Setup: Post Warehouse Receipt, Update Expiration Date and Register Put Away.
        Initialize();
        PostWarehouseReceiptAndRegisterPutAwayForSerialNo(RegisteredWhseActivityLine, '', LibraryRandom.RandInt(10), true);  // Used True to update Expiration Date.

        // Exercise: Create Warehouse Reclassification Journal.
        LibraryVariableStorage.Enqueue(TrackingAction::AssitEditSerialNoAndRemoveExpDate);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        CreateWarehouseReclassificationJournalAndRegister(RegisteredWhseActivityLine, '');

        // Verify: Item Ledger Entry for Serial No and Expiration Date.
        LibraryVariableStorage.Dequeue(SerialNo);
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, RegisteredWhseActivityLine."Item No.", RegisteredWhseActivityLine."Location Code",
          false, SerialNo, '', WorkDate(), -1);  // Used -1 for Quantity.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Purchase, RegisteredWhseActivityLine."Item No.", RegisteredWhseActivityLine."Location Code",
          false, SerialNo, '', WorkDate(), 1);  // Used 1 for Quantity.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure ItemReclassificationWithDifferentExpirationDate()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Setup: Post Warehouse Receipt and Register Put Away.
        Initialize();
        PostWarehouseReceiptAndRegisterPutAwayForSerialNo(RegisteredWhseActivityLine, '', LibraryRandom.RandInt(10), false);

        // Exercise: Create Item Reclassification Journal.
        asserterror CreateItemReclassJournalLine(
            ItemJournalLine, RegisteredWhseActivityLine."Item No.", LocationWhite.Code, LocationWhite.Code, '', true,
            RegisteredWhseActivityLine.Quantity);

        // Verify: Location with Directed Put-Away and Pick Error.
        Assert.ExpectedError(StrSubstNo(DirectedPutAwayAndPickErrorNewExpirationDate, RegisteredWhseActivityLine."Location Code"));
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure ItemReclassificationWithLocationAsRequireReceiveAndBasicLocation()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
        Bin2: Record Bin;
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Quantity: Decimal;
    begin
        // Setup: Create and Post Warehouse Receipt. Item Reclassification with Location as Require Receive to Basic Location.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        LibraryWarehouse.CreateBin(Bin, LocationSilver2.Code, LibraryUtility.GenerateGUID(), '', '');  // Create Bin for LocationSilver2
        LibraryWarehouse.CreateBin(Bin2, LocationSilver2.Code, LibraryUtility.GenerateGUID(), '', '');  // Create Second Bin for LocationSilver2
        CreateItemWithTrackingCode(Item, false, true);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // TrackingAction used in ItemTrackingLinesPageHandler.
        PostWarehouseReceiptAndRegisterPutAway(LocationSilver2.Code, '', Item."No.", Bin.Code, Quantity);
        FindRegisteredPutAway(RegisteredWhseActivityLine, Item."No.");
        CreateItemReclassJournalLine(ItemJournalLine, Item."No.", LocationSilver2.Code, BasicLocation.Code, Bin2.Code, true, Quantity);

        // Exercise: Post Item Reclassification Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Item Ledger Entry for Posted Reclassification.
        VerifyItemLedgerEntry(
          ItemJournalLine."Entry Type"::Transfer, Item."No.", BasicLocation.Code, true, '', RegisteredWhseActivityLine."Lot No.", WorkDate(),
          Quantity);
        VerifyItemLedgerEntry(
          ItemJournalLine."Entry Type"::Transfer, Item."No.", LocationSilver2.Code, false, '', RegisteredWhseActivityLine."Lot No.", 0D,
          -Quantity);  // Used 0D for Blank Date.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ErrorChangingItemTrackingLineOnItemJournal()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        // Setup: Post Warehouse Receipt and Register Put Away. Create and Register Warehouse Physical Journal. Calculate Warehouse Adjustment.
        Initialize();
        PostWarehouseReceiptAndRegisterPutAwayForSerialNo(RegisteredWhseActivityLine, '', LibraryRandom.RandInt(10), false);
        RunWarehouseCalculateInventory(WarehouseJournalLine, '', RegisteredWhseActivityLine."Location Code", '');
        Item.Get(RegisteredWhseActivityLine."Item No.");
        UpdatePhysicalInventoryAndRegister(WarehouseJournalLine, Item."No.");
        CalculateWhseAdjustment(ItemJournalBatch, Item);
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Item."No.");

        // Exercise: Change Serial No. on Item Tracking Line.
        LibraryVariableStorage.Enqueue(TrackingAction::EditSerialNo);  // TrackingAction used in WhseItemTrackingLinesHandler.
        asserterror ItemJournalLine.OpenItemTrackingLines(false);

        // Verify: Error Message while Update Serial No. on Item Journal Line.
        Assert.IsTrue(StrPos(GetLastErrorText, DirectedPutAwayAndPickSerialNo) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure CalculateAndPostWarehouseAdjustmentAfterChangingQuantityOnWarehousePhysicalInventory()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // Setup: Post Warehouse Receipt and Register Put Away. Create and Register Warehouse Physical Journal. Calculate and Post Warehouse Adjustment.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        PostWarehouseReceiptAndRegisterPutAwayForSerialNo(RegisteredWhseActivityLine, '', Quantity, false);
        RunWarehouseCalculateInventory(
          WarehouseJournalLine, '', RegisteredWhseActivityLine."Location Code", RegisteredWhseActivityLine."Item No.");
        Item.Get(RegisteredWhseActivityLine."Item No.");
        UpdatePhysicalInventoryAndRegister(WarehouseJournalLine, Item."No.");

        // Exercise: Calculate and Post Warehouse Adjustment.
        CalculateAndPostWhseAdjustment(Item);

        // Verify: Inventory is Reduced after Posting Warehosue Adjustment.
        VerifyInventoryForItem(Item, Quantity - RegisteredWhseActivityLine.Quantity);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure ErrorChangingItemTrackingLineOnPhysicalInventoryJournal()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Setup: Post Warehouse Receipt and Register Put Away. Create and Register Warehouse Physical Journal. Calculate Inventory on Physical Inventory Journal.
        Initialize();
        PostWarehouseReceiptAndRegisterPutAwayForSerialNo(RegisteredWhseActivityLine, '', LibraryRandom.RandInt(10), false);
        RunWarehouseCalculateInventory(
          WarehouseJournalLine, '', RegisteredWhseActivityLine."Location Code", RegisteredWhseActivityLine."Item No.");
        UpdatePhysicalInventoryAndRegister(WarehouseJournalLine, RegisteredWhseActivityLine."Item No.");
        RunReportCalculateInventory(ItemJournalLine, RegisteredWhseActivityLine."Item No.", '', '', false);
        FindItemJournalLine(
          ItemJournalLine, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name",
          RegisteredWhseActivityLine."Item No.");

        // Exercise: Change Serial No. on Item Tracking Line.
        LibraryVariableStorage.Enqueue(TrackingAction::EditSerialNo);  // TrackingAction used in WhseItemTrackingLinesHandler.
        asserterror ItemJournalLine.OpenItemTrackingLines(false);

        // Verify: Error Message while Update Serial No. on Physical Inventory Journal.
        Assert.IsTrue(StrPos(GetLastErrorText, DirectedPutAwayAndPickSerialNo) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,QuantityToCreatePageHandler')]
    [Scope('OnPrem')]
    procedure CalculateAndPostPhysicalInventoryAfterChangingQuantityOnWarehousePhysicalInventory()
    var
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Post Warehouse Receipt and Register Put Away. Create and Register Warehouse Physical Journal. Calculate and Post Inventory on Physical Inventory Journal.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        PostWarehouseReceiptAndRegisterPutAwayForSerialNo(RegisteredWhseActivityLine, '', Quantity, false);
        RunWarehouseCalculateInventory(
          WarehouseJournalLine, '', RegisteredWhseActivityLine."Location Code", RegisteredWhseActivityLine."Item No.");
        UpdatePhysicalInventoryAndRegister(WarehouseJournalLine, RegisteredWhseActivityLine."Item No.");
        RunReportCalculateInventory(ItemJournalLine, RegisteredWhseActivityLine."Item No.", '', '', false);
        Item.Get(RegisteredWhseActivityLine."Item No.");

        // Exercise: Post Physical Inventory Journal.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // Verify: Inventory is Reduced after Posting Physical Inventory Journal.
        VerifyInventoryForItem(Item, Quantity - RegisteredWhseActivityLine.Quantity);  // Value required for test.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure RegisterReclassificationWithoutChangingItemTrackingLineWithLot()
    var
        Item: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemVariant: Record "Item Variant";
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
    begin
        // Setup: Create Item with Item Variant. Post Warehouse Receipt and Register Put Away.
        Initialize();
        CreateItemWithTrackingCode(Item, false, true);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // TrackingAction used in ItemTrackingLinesPageHandler.
        PostWarehouseReceiptAndRegisterPutAway(LocationWhite.Code, ItemVariant.Code, Item."No.", '', LibraryRandom.RandInt(10));
        FindRegisteredPutAway(RegisteredWhseActivityLine, Item."No.");

        // Exercise: Create Warehouse Reclassification Journal.
        LibraryVariableStorage.Enqueue(TrackingAction::AssitEditLotNo);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        CreateWarehouseReclassificationJournalAndRegister(RegisteredWhseActivityLine, ItemVariant.Code);

        // Verify: Warehouse Entries.
        VerifyWarehouseEntryForWhseJournal(
          RegisteredWhseActivityLine, '', RegisteredWhseActivityLine."Lot No.", RegisteredWhseActivityLine.Quantity, true);
        Assert.IsFalse(
          FindItemLedgerEntry(
            ItemLedgerEntry, ItemLedgerEntry."Entry Type"::Transfer, RegisteredWhseActivityLine."Location Code",
            RegisteredWhseActivityLine."Item No."), ItemLedgerEntriesMustNotExist);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure RegisterReclassificationChangingItemTrackingLineWithLot()
    var
        Item: Record Item;
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        LotNo: Variant;
        NewLotNo: Variant;
    begin
        // Setup: Post Warehouse Receipt and Register Put Away.
        Initialize();
        CreateItemWithTrackingCode(Item, false, true);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // TrackingAction used in ItemTrackingLinesPageHandler.
        PostWarehouseReceiptAndRegisterPutAway(LocationWhite.Code, '', Item."No.", '', LibraryRandom.RandInt(10));
        FindRegisteredPutAway(RegisteredWhseActivityLine, Item."No.");

        // Exercise: Create Warehouse Reclassification Journal.
        LibraryVariableStorage.Enqueue(TrackingAction::AssitEditNewLotNoExpDate);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        CreateWarehouseReclassificationJournalAndRegister(RegisteredWhseActivityLine, '');

        // Verify: Item Ledger Entry and Warehouse Entries.
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(NewLotNo);
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, RegisteredWhseActivityLine."Item No.", RegisteredWhseActivityLine."Location Code",
          false, '', LotNo, 0D, -RegisteredWhseActivityLine.Quantity);  // Used 0D for Blank Date.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, RegisteredWhseActivityLine."Item No.", RegisteredWhseActivityLine."Location Code", true,
          '', NewLotNo, WorkDate(), RegisteredWhseActivityLine.Quantity);
        VerifyWarehouseEntryForWhseJournal(RegisteredWhseActivityLine, '', LotNo, RegisteredWhseActivityLine.Quantity, false);
        VerifyWarehouseEntryForWhseJournal(RegisteredWhseActivityLine, '', NewLotNo, -RegisteredWhseActivityLine.Quantity, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,WhseItemTrackingLinesHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure RegisterReclassificationWithSerialAndLotNo()
    var
        Item: Record Item;
        RegisteredWhseActivityLine: Record "Registered Whse. Activity Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SerialNo: Variant;
        NewSerialNo: Variant;
        LotNo: Variant;
        NewLotNo: Variant;
    begin
        // Setup: Post Warehouse Receipt and Register Put Away.
        Initialize();
        CreateItemWithTrackingCode(Item, true, true);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignSerialAndLot);  // TrackingAction used in ItemTrackingLinesPageHandler.
        PostWarehouseReceiptAndRegisterPutAway(LocationWhite.Code, '', Item."No.", '', LibraryRandom.RandInt(5));
        FindRegisteredPutAway(RegisteredWhseActivityLine, Item."No.");

        // Exercise: Create Warehouse Reclassification Journal.
        LibraryVariableStorage.Enqueue(TrackingAction::AssignNewSerialAndLotNo);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        CreateWarehouseReclassificationJournalAndRegister(RegisteredWhseActivityLine, '');

        // Verify: Warehouse Entry and Item Ledger Entry.
        LibraryVariableStorage.Dequeue(SerialNo);
        LibraryVariableStorage.Dequeue(NewSerialNo);
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(NewLotNo);
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, RegisteredWhseActivityLine."Item No.", RegisteredWhseActivityLine."Location Code",
          false, SerialNo, LotNo, 0D, -RegisteredWhseActivityLine.Quantity);  // Used 0D for Blank Date.
        VerifyItemLedgerEntry(
          ItemLedgerEntry."Entry Type"::Transfer, RegisteredWhseActivityLine."Item No.", RegisteredWhseActivityLine."Location Code", true,
          NewSerialNo, NewLotNo, 0D, RegisteredWhseActivityLine.Quantity);  // Used 0D for Blank Date.
        VerifyWarehouseEntryForWhseJournal(
          RegisteredWhseActivityLine, RegisteredWhseActivityLine."Serial No.", RegisteredWhseActivityLine."Lot No.",
          RegisteredWhseActivityLine.Quantity, false);
        VerifyWarehouseEntryForWhseJournal(RegisteredWhseActivityLine, NewSerialNo, NewLotNo, -RegisteredWhseActivityLine.Quantity, false);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryOnWarehousePhysicalInventoryJournalWithLot()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        LotNo: Variant;
        LotNo2: Variant;
        Quantity: Decimal;
    begin
        // Setup: Create and Post Warehouse Receipt.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithTrackingCode(Item, false, true);
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, '', Item."No.", false, Quantity);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignMultipleLotNo);  // TrackingAction used in ItemTrackingLinesPageHandler.
        CreateAndPostWarehouseReceipt(WarehouseReceiptLine, PurchaseHeader, '', true);  // Post Warehouse Receipt with Tracking.

        // Exercise: Calculate Inventory on Warehouse Physical Journal.
        RunWarehouseCalculateInventory(WarehouseJournalLine, '', LocationWhite.Code, Item."No.");

        // Verify: Warehouse Physical Journal Line.
        LibraryVariableStorage.Dequeue(LotNo);
        LibraryVariableStorage.Dequeue(LotNo2);
        VerifyWarehousePhysicalJournalLineForLot(WarehouseJournalLine, LotNo, Item."No.", Quantity / 2);  // Value Required for Test.
        VerifyWarehousePhysicalJournalLineForLot(WarehouseJournalLine, LotNo2, Item."No.", Quantity / 2); // Value Required for Test.
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure DeleteBinContentWithFlowFilter()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Setup.
        Initialize();
        CreateItemWithTrackingCode(Item, false, true);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // AssignLotNo for Page Handler - ItemTrackingLinesPageHandler.
        CreateAndPostItemJournalLineWithBinAndTracking(ItemJournalLine, Item."No.", Item."Base Unit of Measure", true);

        // Exercise: Delete Bin Content.
        FindItemLedgerEntry(ItemLedgerEntry, ItemLedgerEntry."Entry Type"::"Positive Adjmt.", LocationSilver.Code, Item."No.");
        asserterror DeleteBinContent(
            ItemJournalLine."Location Code", ItemJournalLine."Bin Code", ItemJournalLine."Item No.", ItemLedgerEntry."Lot No.");

        // Verify: Verify Error while Deleting Bin Content.
        Assert.ExpectedError(BinContentError);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,CalculateInventoryPageHandler')]
    [Scope('OnPrem')]
    procedure ErrorChangingLocationCodeOnPhysicalInventoryJournal()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PhysInventoryJournal: TestPage "Phys. Inventory Journal";
        Quantity: Decimal;
    begin
        // Setup: Register Put Away from Warehouse Receipt using Purchase Order with Item Tracking.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithItemTrackingCode(Item, false, true);  // Create Item with Lot.
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // TrackingAction used in ItemTrackingLinesPageHandler.
        RegisterPutAwayFromWarehouseReceiptUsingPurchaseOrderWithItemTracking(PurchaseHeader, Item."No.", Quantity, true);

        // Exercise: Change Location Code on Physical Inventory Journal Page.
        CalculateInventoryOnPhysicalInventoryJournalPage(PhysInventoryJournal, Item."No.");
        asserterror PhysInventoryJournal."Location Code".SetValue(LocationSilver.Code);

        // Verify: Error message for new Location Code.
        Assert.IsTrue(StrPos(GetLastErrorText, LocationCodeErrorOnPhysicalInventoryJournal) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure ErrorChangingNewLotNoOnItemReclassificationJournal()
    begin
        Initialize();
        ItemReclassificationErrorWithNewLotNoAndNewSerialNo(false, true, TrackingAction::AssignLotNo, TrackingAction::SelectEntriesWithLot);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,QuantityToCreatePageHandler,ItemTrackingSummaryHandler')]
    [Scope('OnPrem')]
    procedure ErrorChangingNewSerialNoOnItemReclassificationJournal()
    begin
        Initialize();
        ItemReclassificationErrorWithNewLotNoAndNewSerialNo(
          true, false, TrackingAction::AssignSerialNo, TrackingAction::SelectEntriesWithNewSerialNo);
    end;

    local procedure ItemReclassificationErrorWithNewLotNoAndNewSerialNo(Serial: Boolean; Lot: Boolean; TrackingAction: Option " ",VerifyTracking,AssignLotNo,AssistEdit,AssignSerialNo,AssitEditNewSerialNoExpDate,AssignMultipleLotNo,MultipleExpirationDate,SelectEntries,AssitEditSerialNoAndRemoveExpDate,EditSerialNo,AssitEditLotNo,AssitEditNewLotNoExpDate,AssignSerialAndLot,AssignNewSerialAndLotNo,SelectEntriesWithLot,SelectEntriesWithNewSerialNo; SelectTrackingAction: Option " ",VerifyTracking,AssignLotNo,AssistEdit,AssignSerialNo,AssitEditNewSerialNoExpDate,AssignMultipleLotNo,MultipleExpirationDate,SelectEntries,AssitEditSerialNoAndRemoveExpDate,EditSerialNo,AssitEditLotNo,AssitEditNewLotNoExpDate,AssignSerialAndLot,AssignNewSerialAndLotNo,SelectEntriesWithLot,SelectEntriesWithNewSerialNo)
    var
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Quantity: Decimal;
    begin
        // Setup: Register Put Away from Warehouse Receipt using Purchase Order with Item Tracking.
        Quantity := LibraryRandom.RandInt(10);
        CreateItemWithItemTrackingCode(Item, Serial, Lot);
        LibraryVariableStorage.Enqueue(TrackingAction);  // TrackingAction used in ItemTrackingLinesPageHandler.
        RegisterPutAwayFromWarehouseReceiptUsingPurchaseOrderWithItemTracking(PurchaseHeader, Item."No.", Quantity, true);

        // Exercise: Change New Lot No or New Serial No on Item Reclassification Journal and capture error.
        LibraryVariableStorage.Enqueue(SelectTrackingAction);  // TrackingAction used in ItemTrackingLinesPageHandler.
        asserterror CreateItemReclassJournalLine(ItemJournalLine, Item."No.", LocationWhite.Code, LocationWhite.Code, '', true, Quantity);

        // Verify: Error message on Item Tracking Line.
        if Lot then
            Assert.IsTrue(StrPos(GetLastErrorText, ItemReclassificationErrorWithNewLotNo) > 0, GetLastErrorText)
        else
            Assert.IsTrue(StrPos(GetLastErrorText, ItemReclassificationErrorWithNewSerialNo) > 0, GetLastErrorText);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RegisterWhseItemJnlWithoutNoSeriesInWhseJnlBatch()
    var
        Bin: Record Bin;
        Item: Record Item;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseEntry: Record "Warehouse Entry";
        WhseItemJournal: TestPage "Whse. Item Journal";
    begin
        // Register Warehouse Journal Line for multiple times with blank No. Series in Whse. Journal Batch. Verify User ID is filled in Warehouse Entry.

        // Setup: Create Whse. Journal Batch with blank No. Series. Create Whse. Journal Line and register it.
        Initialize();
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalAndRegister(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, LibraryInventory.CreateItem(Item),
          LibraryRandom.RandDec(100, 2), false);

        // Find the Journal Batch since the Journal Batch Name will be updated after the first journal line is registered.
        FindWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalLine."Journal Template Name", ''); // Blank for No. Series

        // Open Whse. Item Journal page and create Whse. Item Journal Line
        CreateWhseItemJournalFromPage(WhseItemJournal, Bin, WarehouseJournalBatch.Name, Item."No.", LibraryRandom.RandDec(100, 2));

        // Exercise: Register Whse. Item Journal Line
        LibraryVariableStorage.Enqueue(RegisterJournalLines); // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesRegistered); // Enqueue for MessageHandler.
        WhseItemJournal."&Register".Invoke(); // Invoke Register Button

        // Verify: User ID is filled in Warehouse Entries.
        FindWarehouseEntry(WarehouseEntry, WarehouseJournalBatch.Name, WarehouseEntry."Entry Type"::"Positive Adjmt.", Item."No.");
        WarehouseEntry.TestField("User ID", UserId());
        FindWarehouseEntry(WarehouseEntry, WarehouseJournalBatch.Name, WarehouseEntry."Entry Type"::"Negative Adjmt.", Item."No.");
        WarehouseEntry.TestField("User ID", UserId());
    end;

    [Test]
    [HandlerFunctions('WhseJournalBatchesListHandler,WhseCalculateInventoryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithItemsNotOnInventoryAndZoneFilter()
    var
        Bin: Record Bin;
        WhsePhysInvtJournal: TestPage "Whse. Phys. Invt. Journal";
        ItemNo: Code[20];
    begin
        // Verify Warehouse Physical Journal Line is suggested when Calculate Inventory With "Items Not On Inventory" and Zone Filter for Item (exist Warehouse Entries but the actual Quantity is 0 on bin).

        // Setup: Create Item, Register Put away using Purchase Order.
        // Calculate Inventory and register Whse. Phys. Invt. Journal with updating Qty. (Phys. Inventory) to 0, and post adjustment in Item Jounal.
        ItemNo := AdjustInventoryToZeroAfterAddInventoryForItem(Bin);

        // Exercise: Calculate Inventory on Warehouse Physical Journal, set filter Zone Filter.
        CalculateInventoryOnWhsePhysInvtJournalPage(WhsePhysInvtJournal, true, ItemNo, Bin."Zone Code", ''); // "Items not on Inventory" = TRUE, call WhseCalculateInventoryRequestPageHandler.

        // Verify: Verify Whse. Phys. Journal Line is suggested and the Qty. Calculated is correct.
        VerifyWhsePhysJournalLine(Bin."Zone Code", Bin.Code, ItemNo, 0);
    end;

    [Test]
    [HandlerFunctions('WhseJournalBatchesListHandler,WhseCalculateInventoryRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryWithItemsNotOnInventoryAndBinFilter()
    var
        Bin: Record Bin;
        WhsePhysInvtJournal: TestPage "Whse. Phys. Invt. Journal";
        ItemNo: Code[20];
    begin
        // Verify Warehouse Physical Journal Line is suggested when Calculate Inventory With "Items Not On Inventory" and Bin Filter for Item (exist Warehouse Entries but the actual Quantity is 0 on bin).

        // Setup: Create Item, Register Put away using Purchase Order.
        // Calculate Inventory and register Whse. Phys. Invt. Journal with updating Qty. (Phys. Inventory) to 0, and post adjustment in Item Jounal.
        ItemNo := AdjustInventoryToZeroAfterAddInventoryForItem(Bin);

        // Exercise: Calculate Inventory on Warehouse Physical Journal, set filter Bin Filter.
        CalculateInventoryOnWhsePhysInvtJournalPage(WhsePhysInvtJournal, true, ItemNo, '', Bin.Code); // "Items not on Inventory" = TRUE, call WhseCalculateInventoryRequestPageHandler.

        // Verify: Verify Whse. Phys. Journal Line is suggested and the Qty. Calculated is correct.
        VerifyWhsePhysJournalLine(Bin."Zone Code", Bin.Code, ItemNo, 0);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure RegisteringWhseJournalLineChecksBinContentFilteringByLotNo()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemNo: Code[20];
        Quantity: Decimal;
    begin
        // [FEATURE] [Wharehouse Item Journal] [Bin Content] [Item Tracking]
        // [SCENARIO 362621] Registering Whse Journal Line includes BinContent check filtering by "Lot No"
        Initialize();
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Bin with Content for Item with Tracking
        ItemNo := CreateBinWithContentForItem(Bin, BinContent);

        // [GIVEN] Create and register Whse Journal Line with Positive Adjustment of Quantity = "Q1" on Lot "L" for Item
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, "Warehouse Journal Template Type"::Item, Bin."Location Code");
        CreateWhseJournalLineWithTracking(
          WarehouseJournalLine, WarehouseJournalBatch, Bin, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", true);

        // [GIVEN] Create Pick for Item of Quantity = "Q2";
        CreateWhseActivityLineForPick(BinContent); // MOCK Pick for quantity = "Q2"

        // [GIVEN] Create Whse Journal Line with Negative Adjustment of Quantity = "-Q1" on Lot "L" for Item
        CreateWhseJournalLineWithTracking(
          WarehouseJournalLine, WarehouseJournalBatch, Bin, WarehouseJournalLine."Entry Type"::"Negative Adjmt.", ItemNo, -Quantity);

        // [WHEN] Register Whse Journal Line with negative Quantity
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", true);

        // [THEN] Bin Content is deleted
        Assert.IsFalse(BinContent.Find(), BinContentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisteringWhseJournalLineThowsErrorIfQuantityIsNotSufficient()
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Item: Record Item;
        Quantity: Decimal;
    begin
        // [FEATURE] [Wharehouse Item Journal] [Bin Content]
        // [SCENARIO 362621] Registering Whse Journal Line thows Error if Quantity is not sufficient for negative admt. without Tracking
        Initialize();
        Quantity := LibraryRandom.RandInt(10);

        // [GIVEN] Bin with Content for Item
        LibraryInventory.CreateItem(Item);
        FindBin(Bin, LocationWhite.Code, true);
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");

        // [GIVEN] Create and register Whse Journal Line with Positive Adjustment of Quantity = "Q1"
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, "Warehouse Journal Template Type"::Item, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", true);

        // [GIVEN] Create Pick for Item of Quantity = "Q2"
        CreateWhseActivityLineForPick(BinContent); // MOCK Pick for Quantity = "Q2"

        // [GIVEN] Create Whse Journal Line with Negative Adjustment of Quantity = "Q1" without Tracking.
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Negative Adjmt.", Item."No.", -Quantity);

        // [WHEN] Register Whse Journal Line with negative Quantity
        asserterror LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", true);

        // [THEN] Error is thrown while checking Quantity in Bin Content
        Assert.ExpectedError(StrSubstNo(BinContentQuantityErr));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureRequiredInWhseJournalIfItemNoIsFilled()
    var
        WhseJnlLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Warehouse Item Journal] [UT]
        // [SCENARIO 372282] Field "Unit of Measure Code" in warehouse journal cannot be empty if "Item No." is not empty

        // [GIVEN] Warehouse journal line with "Item No."
        WhseJnlLine.Init();
        WhseJnlLine."Item No." := LibraryUtility.GenerateGUID();

        // [WHEN] Set "Unit of Measure Code" to empty string
        asserterror WhseJnlLine.Validate("Unit of Measure Code", '');

        // [THEN] Error mesage: "Unit of Measure Code must have a value"
        Assert.ExpectedError(StrSubstNo(UnitOfMeasureMustHaveValueErr, WhseJnlLine.FieldCaption("Unit of Measure Code")));
        Assert.ExpectedErrorCode(TestFieldErrorErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnitOfMeasureNotRequiredInWhseJournalIfItemNoNotFilled()
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WhseJnlLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
    begin
        // [FEATURE] [Warehouse Item Journal]
        // [SCENARIO 372282] Field "Unit of Measure Code" in warehouse journal can be empty if "Item No." is empty

        // [GIVEN] Warehouse journal line with empty "Item No."
        Initialize();
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalLine(WhseJnlLine, Bin, WarehouseJournalTemplate.Type::Item, '', 0, false);

        // [WHEN] Set "Unit of Measure Code" to empty string
        WhseJnlLine.Validate("Unit of Measure Code", '');
        // [THEN] Empty "Unit os Measure Code" is accepted
        WhseJnlLine.TestField("Unit of Measure Code", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysicalInventorySkipsILEOnDeletedLocation()
    var
        Location: array[2] of Record Location;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Physical Inventory Journal]
        // [SCENARIO] When running physical inventory calculation, item ledger entries on deleted location should be skipped

        // [GIVEN] 2 locations "L1" and "L2"
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[1]);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location[2]);

        // [GIVEN] Post positive adjustment and negative adjustment on location "L1", and positive adjustment on "L2". So there is inventory left only on "L2".
        LibraryInventory.CreateItem(Item);
        Qty := LibraryRandom.RandDec(100, 2);
        LibraryInventory.PostPositiveAdjustment(Item, Location[1].Code, '', '', Qty, WorkDate(), Item."Unit Cost");
        LibraryInventory.PostPositiveAdjustment(Item, Location[2].Code, '', '', Qty, WorkDate(), Item."Unit Cost");
        LibraryInventory.PostNegativeAdjustment(Item, Location[1].Code, '', '', Qty, WorkDate(), Item."Unit Cost");

        // [GIVEN] Delete location "L1"
        Location[1].Delete(true);

        // [WHEN] Run "Calculate Physical Inventory" for both locations
        RunReportCalculateInventory(ItemJournalLine, Item."No.", '', '', true);

        // [THEN] No item journal lines created for location "L1"
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.SetRange("Location Code", Location[1].Code);
        Assert.RecordIsEmpty(ItemJournalLine);

        // [THEN] 1 item journal line created for location "L2"
        ItemJournalLine.SetRange("Location Code", Location[2].Code);
        Assert.AreEqual(1, ItemJournalLine.Count, ItemJnlLineMustExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PhysicalInventoryOnBlankLocationCode()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
    begin
        // [FEATURE] [Physical Inventory Journal]
        // [SCENARIO] Physical inventory journal line should be created when runnning "Calculate Physical Inventory" with blank location code

        // [GIVEN] Item "I" with inventory on hand on blank location
        LibraryInventory.CreateItem(Item);
        LibraryInventory.PostPositiveAdjustment(Item, '', '', '', 1, WorkDate(), Item."Unit Cost");

        // [WHEN] Run "Calculate Physical Inventory"
        RunReportCalculateInventory(ItemJournalLine, Item."No.", '', '', true);

        // [THEN] 1 physical inventory journal line is created
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.SetRange("Location Code", '');
        Assert.AreEqual(1, ItemJournalLine.Count, ItemJnlLineMustExistErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RegisteringWhseItemJournalWithBlankItemNo()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        Bin: Record Bin;
    begin
        // [FEATURE] [Wharehouse Item Journal]
        // [SCENARIO 376074] Registering Wharehouse Item Journal with blank "Item No." should be prohibited
        Initialize();

        // [GIVEN] Wharehouse Journal Line with blank "Item No."
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, '', LibraryRandom.RandDec(10, 2), false);

        // [WHEN] Register Wharehouse Journal Line
        asserterror LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, true);

        // [THEN] Error is thrown: "Item No. must have a value in Warehouse Journal Line"
        Assert.ExpectedError(ItemNoErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseJournalNotAffectingReservationPostedWithoutConfirmation()
    var
        Item: Record Item;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        Quantity: Decimal;
        DeltaQty: Decimal;
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 377903] Warehouse journal is posted without error when warehouse stock is reserved if journal line being posted does not affect reservation

        // [GIVEN] Post item stock on a warehouse location "L", stock quantity = "X"
        // [GIVEN] Create a sales order, quantity = "X" / 2, and reserve sales line
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateReservedStockOnWarehouse(Bin, Item, Quantity * 2, Quantity);

        // [GIVEN] Create warehouse journal batch "B1", create journal line with quantity = -"X"
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", -Quantity * 2, false);
        // [GIVEN] Create another warehouse journal batch "B2", and create a journal line in this batch with quantity = "X" / 2
        DeltaQty := LibraryRandom.RandInt(50);
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", Quantity - DeltaQty, false);

        // [WHEN] Post batch "B2"
        LibraryVariableStorage.Enqueue(RegisterJournalLines);
        LibraryVariableStorage.Enqueue(JournalLinesRegistered);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", false);

        // [THEN] Journal batch is posted without additional user confirmation
        VerifyBinContent(Bin, Item."No.", Quantity * 3 - DeltaQty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure WhseJournalAffectingReservationRequiresConfirmation()
    var
        Item: Record Item;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation]
        // [SCENARIO 377903] Confirmation is required when posting warehouse journal if journal line being posted affects reservation

        // [GIVEN] Post item stock on a warehouse location "L", stock quantity = "X"
        // [GIVEN] Create a sales order, quantity = "X" / 2, and reserve sales line
        Quantity := LibraryRandom.RandIntInRange(100, 200);
        CreateReservedStockOnWarehouse(Bin, Item, Quantity * 2, Quantity);

        // [GIVEN] Create warehouse journal batch, create journal line with quantity = -"X"
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", -Quantity - LibraryRandom.RandInt(100), false);

        // [WHEN] Post journal batch
        LibraryVariableStorage.Enqueue(RegisterJournalLines);
        LibraryVariableStorage.Enqueue(ReservationExistMsg);
        LibraryVariableStorage.Enqueue(JournalLinesRegistered);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", false);

        // [THEN] Confirmation is requested
        // Confirmation request is verified in ConfirmHandler
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure LotFilterIsAppliedToWhseAdjustmentCalculation()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LotOrSerialNos: array[5] of Code[20];
    begin
        // [FEATURE] [Item Tracking] [Warehouse Adjustment]
        // [SCENARIO 381478] "Lot No. Filter" from Item is applied when running "Calculate Whse. Adjustment" job.
        Initialize();

        // [GIVEN] Lot-tracked Item.
        // [GIVEN] Location with "Directed Put-away and Pick".
        // [GIVEN] Several Warehouse Journal Lines with lot tracking are posted for Item. Lot nos. = "L1".."Ln". Quantity on each line = 1.
        CreateAndRegisterWhseJournalLineWithTracking(Item, LotOrSerialNos, ItemTrackingMode::"Lot No");

        // [WHEN] Calculate Whse. Adjustment with "Lot No. Filter" = "L1".
        Item.SetRange("Lot No. Filter", LotOrSerialNos[1]);
        CalculateWhseAdjustment(ItemJournalBatch, Item);

        // [THEN] One Item Journal Line is created. Quantity = 1.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Item."No.");
        Assert.RecordCount(ItemJournalLine, 1);
        ItemJournalLine.TestField(Quantity, 1);

        // [THEN] One Item Tracking Line with lot "L1" is created for the Item Journal Line.
        // verification is done in ItemTrackingLinesHandler
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Lot No");
        LibraryVariableStorage.Enqueue(LotOrSerialNos[1]);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler,ItemTrackingLinesHandler')]
    [Scope('OnPrem')]
    procedure SerialNoFilterIsAppliedToWhseAdjustmentCalculation()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        LotOrSerialNos: array[5] of Code[20];
    begin
        // [FEATURE] [Item Tracking] [Warehouse Adjustment]
        // [SCENARIO 381478] "Serial No. Filter" from Item is applied when running "Calculate Whse. Adjustment" job.
        Initialize();

        // [GIVEN] Serial No.-tracked Item.
        // [GIVEN] Location with "Directed Put-away and Pick".
        // [GIVEN] Several Warehouse Journal Lines with lot tracking are posted for Item. Serial nos. = "S1".."Sn". Quantity on each line = 1.
        CreateAndRegisterWhseJournalLineWithTracking(Item, LotOrSerialNos, ItemTrackingMode::"Serial No");

        // [WHEN] Calculate Whse. Adjustment with "Serial No. Filter" = "S1".
        Item.SetRange("Serial No. Filter", LotOrSerialNos[1]);
        CalculateWhseAdjustment(ItemJournalBatch, Item);

        // [THEN] One Item Journal Line is created. Quantity = 1.
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Item."No.");
        Assert.RecordCount(ItemJournalLine, 1);
        ItemJournalLine.TestField(Quantity, 1);

        // [THEN] One Item Tracking Line with serial no. "S1" is created for the Item Journal Line.
        // verification is done in ItemTrackingLinesHandler
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Serial No");
        LibraryVariableStorage.Enqueue(LotOrSerialNos[1]);
        ItemJournalLine.OpenItemTrackingLines(false);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ResidualQtyBaseInBinIsWrittenOffWhenQtyIsZeroedOutByWhseJournal()
    var
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemNo: Code[20];
        UnitOfMeasureCode: Code[10];
        QtyInUOM: Decimal;
    begin
        // [FEATURE] [Rounding]
        // [SCENARIO 382095] When quantity in bin is turned to zero by registering warehouse journal, residual base quantity should be zeroed out too.
        Initialize();

        // [GIVEN] Item "I" with alternate unit of measure "PACK" has contains 3 base units ("pcs").
        QtyInUOM := 3;
        CreateItemWithAlternateUnitOfMeasure(ItemNo, UnitOfMeasureCode, QtyInUOM);

        // [GIVEN] Positive warehouse adjustment of item "I" is registered to bin "B". Quantity = 0.33333 PACK. Base quantity = 1 pc.
        FindBin(Bin, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        CreateAndRegisterWhseJournalWithAlternateUOM(
          WarehouseJournalBatch, ItemNo, UnitOfMeasureCode, Bin, Round(1 / QtyInUOM, 0.00001), 1);

        // [WHEN] Register negative warehouse adjustment of item "I" from bin "B". Quantity = -0.33333 PACK. Base quantity = -0.99999 pcs.
        CreateAndRegisterWhseJournalWithAlternateUOM(
          WarehouseJournalBatch, ItemNo, UnitOfMeasureCode, Bin, -Round(1 / QtyInUOM, 0.00001), -Round(1 / QtyInUOM, 0.00001) * QtyInUOM);

        // [THEN] Bin "B" contains 0 pcs and 0 PACKs of item "I".
        VerifyWarehouseEntryForZeroQty(ItemNo, Bin.Code);

        // [THEN] Adjustment bin contains 0 pcs and 0 PACKs of item "I".
        VerifyWarehouseEntryForZeroQty(ItemNo, LocationWhite."Adjustment Bin Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure ExcessivelyWrittenOffQtyBaseByWhseJournalIsZeroedOut()
    var
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemNo: Code[20];
        UnitOfMeasureCode: Code[10];
        QtyInUOM: Decimal;
    begin
        // [FEATURE] [Rounding]
        // [SCENARIO 382095] When quantity in bin is turned to zero by registering warehouse journal, excessively written off base quantity should be zeroed out too.
        Initialize();

        // [GIVEN] Item "I" with alternate unit of measure "PACK" has contains 3 base units ("pcs").
        QtyInUOM := 3;
        CreateItemWithAlternateUnitOfMeasure(ItemNo, UnitOfMeasureCode, QtyInUOM);

        // [GIVEN] Positive warehouse adjustment of item "I" is registered to bin "B". Quantity = 0.33333 PACK. Base quantity = 0.99999 pc.
        FindBin(Bin, LocationWhite.Code, true);
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, Bin."Location Code");
        CreateAndRegisterWhseJournalWithAlternateUOM(
          WarehouseJournalBatch, ItemNo, UnitOfMeasureCode, Bin, Round(1 / QtyInUOM, 0.00001), Round(1 / QtyInUOM, 0.00001) * QtyInUOM);

        // [WHEN] Register negative warehouse adjustment of item "I" from bin "B". Quantity = -0.33333 PACK. Base quantity = -1 pcs.
        CreateAndRegisterWhseJournalWithAlternateUOM(
          WarehouseJournalBatch, ItemNo, UnitOfMeasureCode, Bin, -Round(1 / QtyInUOM, 0.00001), -1);

        // [THEN] Bin "B" contains 0 pcs and 0 PACKs of item "I".
        VerifyWarehouseEntryForZeroQty(ItemNo, Bin.Code);

        // [THEN] Adjustment bin contains 0 pcs and 0 PACKs of item "I".
        VerifyWarehouseEntryForZeroQty(ItemNo, LocationWhite."Adjustment Bin Code");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure BinContentCreatedByWhseJnlRegisteringHasNoMaxQtyLimit()
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Location: Record Location;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
    begin
        // [FEATURE] [Open Shop Floor Bin] [Bin] [Bin Content]
        // [SCENARIO 201466] Bin content automatically created by the warehouse journal registering routine, should not have the Max. Qty. limit
        Initialize();

        // [GIVEN] Location "L" with directed put-away and pick
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);
        FindBin(Bin, Location.Code, false);
        // [GIVEN] Empty bin "B" configured as the open shop floor bin for the location "L"
        Location.Validate("Open Shop Floor Bin Code", Bin.Code);
        Location.Modify(true);

        // [WHEN] Post positive adjustment on bin "B" via warehouse journal
        CreateWarehouseJournalAndRegister(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, LibraryInventory.CreateItemNo(),
          LibraryRandom.RandDec(100, 2), false);

        // [THEN] Bin content for the bin "B" has "Max. Qty." = 0, "Fixed" = TRUE
        BinContent.SetRange("Location Code", Location.Code);
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.FindFirst();
        BinContent.TestField("Max. Qty.", 0);
        BinContent.TestField(Fixed, true);
    end;

    [Test]
    [HandlerFunctions('DummyConfirmHandler')]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForPurchaseAndForWhseUndoQuantity()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Purchase]
        // [SCENARIO 382088] Only one Warehouse Register is created for posting any quantity of lines in Purchase Order and also for undo receipt of a Purchase Order
        Initialize();

        // [GIVEN] Purchase order with two lines at Bin Mandatory Location
        CreatePurchaseOrderTwoLines(PurchaseHeader);

        // [WHEN] Post the Purchase Order
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);

        // [WHEN] Undo Receipt for the Purchase Order
        FilterPurchRcptLineByOrderNo(PurchRcptLine, PurchaseHeader."No.");
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        CODEUNIT.Run(CODEUNIT::"Undo Purchase Receipt Line", PurchRcptLine);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [HandlerFunctions('DummyConfirmHandler')]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForSaleAndForWhseUndoQuantity()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentLine: Record "Sales Shipment Line";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Sale]
        // [SCENARIO 382088] Only one Warehouse Register is created for posting any quantity of lines in Sales Order and also for undo shipment of a Sales Order
        Initialize();

        // [GIVEN] Sales order with two lines at Bin Mandatory Location
        CreateSalesOrderTwoLines(SalesHeader);

        // [WHEN] Post the Sales Order
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibrarySales.PostSalesDocument(SalesHeader, true, false);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);

        // [WHEN] Undo Shipment for the Sales Order
        FilterSalesShipmentLineByOrderNo(SalesShipmentLine, SalesHeader."No.");
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        CODEUNIT.Run(CODEUNIT::"Undo Sales Shipment Line", SalesShipmentLine);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForTransfer()
    var
        TransferHeader: Record "Transfer Header";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Transfer]
        // [SCENARIO 382088] Only one Warehouse Register is created for posting any quantity of lines in Transfer Order as Sipment and also as Receipt
        Initialize();

        // [GIVEN] Transfer order with two lines at Bin Mandatory Location
        CreateTransferOrderTwoLines(TransferHeader);

        // [WHEN] Post Shipment of the Transfer Order
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);

        // [WHEN] Post Receipt of the Transfer Order
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [HandlerFunctions('DummyConfirmHandler')]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForServiceAndForWhseUndoQuantity()
    var
        ServiceHeader: Record "Service Header";
        ServiceShipmentLine: Record "Service Shipment Line";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Service]
        // [SCENARIO 382088] Only one Warehouse Register is created for posting any quantity of lines in Service Order and also for undo shipment of a Service Order
        Initialize();

        // [GIVEN] Service order with two item lines at Bin Mandatory Location
        CreateServiceOrderTwoItemLines(ServiceHeader);

        // [WHEN] Post shipment of the Service Order
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);

        // [WHEN] Undo Shipment for the Service Order
        FilterServiceShipmentLineByOrderNo(ServiceShipmentLine, ServiceHeader."No.");
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        CODEUNIT.Run(CODEUNIT::"Undo Service Shipment Line", ServiceShipmentLine);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [HandlerFunctions('DummyConfirmHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForJob()
    var
        JobJournalLine: Record "Job Journal Line";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Job]
        // [SCENARIO 382088] Only one Warehouse Register is created for posting any quantity of lines in Job Journal
        Initialize();

        // [GIVEN] Job Journal with two item lines at Bin Mandatory Location
        CreateJobJournalTwoItemLines(JobJournalLine);

        // [WHEN] Post Job Journal
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibraryJob.PostJobJournal(JobJournalLine);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForItemJournalBatch()
    var
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Item Journal]
        // [SCENARIO 382088] Only one Warehouse Register is created for posting any quantity of lines in Item Journal
        Initialize();

        // [GIVEN] Item Journal with two lines at Bin Mandatory Location
        CreateItemJournalTwoLines(ItemJournalBatch);

        // [WHEN] Post Item Journal
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForCreateWarehouseLocation()
    var
        Location: Record Location;
        Bin: Record Bin;
        CreateWarehouseLocation: Report "Create Warehouse Location";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Create Warehouse]
        // [SCENARIO 382088] Only one Warehouse Register is created when creating Warehouse Location for any quantity of Item Ledger Entries
        Initialize();

        // [GIVEN] Two Item Ledger Entries at simple Location L
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        CreateTwoItemLedgerEntriesAtLocation(Location);

        CreateWarehouseLocation.SetHideValidationDialog(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        CreateWarehouseLocation.InitializeRequest(Location.Code, Bin.Code);
        CreateWarehouseLocation.UseRequestPage(false);
        Commit();

        // [WHEN] Create Warehouse Location from L
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        CreateWarehouseLocation.RunModal();

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForProductionOrderOutput()
    var
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Production Order]
        // [SCENARIO 382088] Only one Warehouse Register is created when Post Output Journal with any quantity of lines
        Initialize();
        CreateOutputJournalTwoLines();
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();

        // [WHEN] Post the Output Journal
        LibraryManufacturing.PostOutputJournal();

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    procedure CreateOutputJournalFromProdOrderWithItemWithVariants()
    var
        Location: Record Location;
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        BinCodeList: List of [Code[20]];
        VariantCode: Code[10];
    begin
        Initialize();
        // [GIVEN] Location with bins
        BinCodeList := CreateLocationWithBins(Location, 3);

        // [GIVEN] Item with variants and replenishment system "Prod. Order" and manufacturing policy "Make-to-Order"
        CreateItemWithReplenishmentSystemAndManufacturingPolicy(Item, "Replenishment System"::"Prod. Order", "Manufacturing Policy"::"Make-to-Order");
        Evaluate(VariantCode, LibraryRandom.RandText(5));
        AddVariantsToItem(Item, VariantCode);
        SetDefaultBinContent(Item."No.", VariantCode, Location.Code, BinCodeList.Get(1));

        // [GIVEN] Production Order with 1 line 
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, Item."No.", 2);

        // [GIVEN] Production Order updated with Variant, Location and Bin Code
        ProductionOrder.Validate("Variant Code", VariantCode);
        ProductionOrder.Validate("Location Code", Location.Code);
        ProductionOrder.Validate("Bin Code", BinCodeList.Get(3));
        ProductionOrder.Modify();

        // [GIVEN] Production order is refreshed
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [GIVEN] Output Journal Template and Batch are created
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Output, ItemJournalTemplate.Name);

        // [WHEN] Create Output Journal for Production Order Line
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, Item."No.", ProductionOrder."No.");

        // [THEN] Output Journal Line is created for Item No., Variant Code with defined Location Code and Bin Code
        ItemJournalLine.TestField("Location Code", Location.Code);
        ItemJournalLine.TestField("Bin Code", BinCodeList.Get(3));
    end;

    [Test]
    [HandlerFunctions('ItemTrackLinesPageHandler,QuantityToCreateNewLotNoPageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForProductionOrderConsumption()
    var
        ConsumptionItemJournalBatch: Record "Item Journal Batch";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Production Order]
        // [SCENARIO 382088] Only one Warehouse Register is created when Post Consumption Journal with any quantity of lines
        Initialize();

        // [GIVEN] Consumption Journal With Two Lines at Bin Mandatory Location
        CreateConsumptionJournalTwoLines(ConsumptionItemJournalBatch);

        // [WHEN] Post the Consumption Journal
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibraryInventory.PostItemJournalLine(ConsumptionItemJournalBatch."Journal Template Name", ConsumptionItemJournalBatch.Name);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [HandlerFunctions('PostProductionJournalHandler,DummyConfirmHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForProductionOrderFlushedConsumption()
    var
        ProductionOrder: Record "Production Order";
        WarehouseRegisterLastNo: Integer;
        ProdOrderLineLineNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Production Order]
        // [SCENARIO 382088] Only one Warehouse Register is created when Post Flushed Consumption Production Journal with any quantity of lines
        Initialize();

        // [GIVEN] Production Order with One Line of Flushing Consumption at Bin Mandatory Location
        ProdOrderLineLineNo := CreateProductionOrderFlushingConsumptionOneLine(ProductionOrder);

        // [WHEN] Open and post Production Journal
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibraryManufacturing.OpenProductionJournal(ProductionOrder, ProdOrderLineLineNo);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForAssembly()
    var
        AssemblyHeader: Record "Assembly Header";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Assembly]
        // [SCENARIO 382088] Only one Warehouse Register is created when Post Assembly with any quantity of components
        Initialize();

        // [GIVEN] Assembly Order With Two Components at Bin Mandatory Location
        CreatePickedAssemblyOrderWithTwoComponents(AssemblyHeader);

        // [WHEN] Post Assembly Order
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForWarehouseReceipt()
    var
        WhseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Warehouse Receipt]
        // [SCENARIO 382088] Only one Warehouse Register is created when Post Warehouse Receipt with any quantity of lines
        Initialize();

        // [GIVEN] Warehouse Receipt with two lines
        CreatePurchaseOrderTwoLinesWithWhseReceipt(WhseReceiptLine);

        // [WHEN] Post Warehouse Receipt
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Receipt", WhseReceiptLine);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForRegisterWarehouseActivityAndForWarehouseShipment()
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Warehouse Shipment] [Warehouse Activity]
        // [SCENARIO 382088] Only one Warehouse Register is created when Register Warehouse Activity or Post Warehouse Shipment with any quantity of lines
        Initialize();

        // [GIVEN] Sales Order SO with Two Lines
        CreateSalesOrderTwoLinesWithWhseShipmentAndPick(WarehouseShipmentLine);

        // [WHEN] Register Warehouse Activity (Pick) for the SO
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Sales Order",
          WarehouseShipmentLine."Source No.", WarehouseActivityHeader.Type::Pick);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);

        // [WHEN] Post Warehouse Shipment for the SO
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        CODEUNIT.Run(CODEUNIT::"Whse.-Post Shipment", WarehouseShipmentLine);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForWarehouseJournalBatch()
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Warehouse Journal]
        // [SCENARIO 382088] Only one Warehouse Register is created when Register Warehouse Journal Batch with any quantity of lines
        Initialize();

        // [GIVEN] Warehouse Journal Batch with Two Lines
        CreateWarehouseJournalBatchWithTwoLines(WarehouseJournalLine);

        // [WHEN] Register Warehouse Journal Batch
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        CODEUNIT.Run(CODEUNIT::"Whse. Jnl.-Register Batch", WarehouseJournalLine);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [HandlerFunctions('DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure SingleWarehouseRegisterForPostWarehouseActivity()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
        WarehouseRegisterLastNo: Integer;
    begin
        // [FEATURE] [Warehouse Register] [Warehouse Activity]
        // [SCENARIO 382088] Only one Warehouse Register is created when Post Warehouse Activity with any quantity of lines
        Initialize();

        // [GIVEN] Warehouse Activity (Put-away) with Two Lines
        CreatePurchaseOrderTwoLinesWithPutaway(WarehouseActivityLine);

        // [WHEN] Post Warehouse Activity
        WarehouseRegisterLastNo := FindLastWarehouseRegisterNo();
        CODEUNIT.Run(CODEUNIT::"Whse.-Activity-Post", WarehouseActivityLine);

        // [THEN] Only one Warehouse Register is created
        VerifyLastWarehouseRegisterNo(WarehouseRegisterLastNo + 1);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure ReservationBindingAfterPickingProdOrderComponentLinkedToPurchase()
    var
        Location: Record Location;
        Bin: Record Bin;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        DemandQty: Decimal;
    begin
        // [FEATURE] [Order tracking] [Pick] [Reservation]
        // [SCENARIO 201721] Item tracking binding should be changed from purchase to item ledger when warehouse pick is registered

        Initialize();

        // [GIVEN] Location with shipment and pick required
        CreateComponentsLocationWithBin(Location, Bin);

        // [GIVEN] Lot tracked item "CI" with order tracking and action messages enabled
        CreateTrackedItem(ComponentItem);

        // [GIVEN] Production order producing an item "PI" that includes "CI" as a component. Quantity to produce is 5. Due date is 25.01.18
        DemandQty := LibraryRandom.RandInt(99);
        CreateProductionOrderWithComponent(ProductionOrder, ComponentItem."No.", Location.Code, Bin.Code, DemandQty);

        // [GIVEN] Purchase order for component item "CI". Quantity = 5, expected receipt date = 20.01.18
        CreatePurchaseOrderUpdateReceiptDate(
          PurchaseHeader, Location.Code, '', ComponentItem."No.", DemandQty, ProductionOrder."Starting Date");
        // [GIVEN] Post item stock of 5 PCS with lot no. = "L1"
        LotNo := PostItemPositiveAdjmtWithLotTracking(ComponentItem."No.", Location.Code, Bin.Code, DemandQty);

        // [GIVEN] Create a warehouse pick from the production order
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [GIVEN] Set lot no. = "L1" in warehouse pick lines
        WarehouseActivityLine.SetRange("Item No.", ComponentItem."No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo);

        // [WHEN] Register the warehouse pick
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] Production order component "CI" is tracked against item ledger.
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Prod. Order Component", ProductionOrder.Status.AsInteger(), ProductionOrder."No.",
          ReservationEntry."Reservation Status"::Tracking, -DemandQty, LotNo);
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Item Ledger Entry", 0, '', ReservationEntry."Reservation Status"::Tracking, DemandQty, LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure ReservationBindingAfterPartialPickingProdOrderComponentLinkedToPurchase()
    var
        Location: Record Location;
        Bin: Record Bin;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        DemandQty: Decimal;
        SurplusQty: Decimal;
    begin
        // [FEATURE] [Order tracking] [Pick] [Reservation]
        // [SCENARIO 201721] Item tracking binding should be changed from purchase to item ledger when item is partially picked and item stock is sufficient to cover the demand

        Initialize();

        // [GIVEN] Location with shipment and pick required
        CreateComponentsLocationWithBin(Location, Bin);

        // [GIVEN] Lot tracked item "CI" with order tracking and action messages enabled
        CreateTrackedItem(ComponentItem);

        // [GIVEN] Production order producing an item "PI" that includes "CI" as a component. Quantity to produce is 5. Due date is 25.01.18
        DemandQty := LibraryRandom.RandIntInRange(10, 100);
        SurplusQty := LibraryRandom.RandInt(99);
        CreateProductionOrderWithComponent(ProductionOrder, ComponentItem."No.", Location.Code, Bin.Code, DemandQty);
        // [GIVEN] Purchase order for component item "CI". Quantity = 5, expected receipt date = 20.01.18
        CreatePurchaseOrderUpdateReceiptDate(
          PurchaseHeader, Location.Code, '', ComponentItem."No.", DemandQty, ProductionOrder."Starting Date");

        // [GIVEN] Post item stock of 100 PCS with lot no. = "L1"
        LotNo := PostItemPositiveAdjmtWithLotTracking(ComponentItem."No.", Location.Code, Bin.Code, DemandQty + SurplusQty);
        // [GIVEN] Create a warehouse pick from the production order
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [GIVEN] Set lot no. = "L1" in warehouse pick lines, set "Qty. to Handle" = 2 to pick partial quantitiy
        WarehouseActivityLine.SetRange("Item No.", ComponentItem."No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo);
        if WarehouseActivityLine.FindSet() then
            repeat
                WarehouseActivityLine.Validate("Qty. to Handle", LibraryRandom.RandInt(DemandQty - 1));
            until WarehouseActivityLine.Next() = 0;

        // [WHEN] Register the warehouse pick
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] Prod. order consumption is tracked against the item ledger entry. 95 pcs are tracked as surplus quantity. 5 pcs from purchase order are tracked as surplus.
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Prod. Order Component", ProductionOrder.Status.AsInteger(), ProductionOrder."No.",
          ReservationEntry."Reservation Status"::Tracking, -DemandQty, LotNo);
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Item Ledger Entry", 0, '', ReservationEntry."Reservation Status"::Tracking, DemandQty, LotNo);
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Item Ledger Entry", 0, '', ReservationEntry."Reservation Status"::Surplus, SurplusQty, LotNo);
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.",
          ReservationEntry."Reservation Status"::Surplus, DemandQty, '');
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure ReservationBindingAfterPartialPickingProdOrderComponentLinkedToPurchaseInsuffucientStock()
    var
        Location: Record Location;
        Bin: Record Bin;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
        ReservationEntry: Record "Reservation Entry";
        LotNo: Code[50];
        DemandQty: Decimal;
        StockQty: Decimal;
    begin
        // [FEATURE] [Order tracking] [Pick] [Reservation]
        // [SCENARIO 201721] Item tracking binding should be split between purchase and item ledger when item is partially picked and item stock is insufficient to cover the demand

        Initialize();

        // [GIVEN] Location with shipment and pick required
        CreateComponentsLocationWithBin(Location, Bin);

        // [GIVEN] Lot tracked item "CI" with order tracking and action messages enabled
        CreateTrackedItem(ComponentItem);
        // [GIVEN] Production order producing an item "PI" that includes "CI" as a component. Quantity to produce is 5. Due date is 25.01.18
        DemandQty := LibraryRandom.RandIntInRange(50, 100);
        StockQty := LibraryRandom.RandInt(30);
        CreateProductionOrderWithComponent(ProductionOrder, ComponentItem."No.", Location.Code, Bin.Code, DemandQty);
        // [GIVEN] Purchase order for component item "CI". Quantity = 5, expected receipt date = 20.01.18
        CreatePurchaseOrderUpdateReceiptDate(
          PurchaseHeader, Location.Code, '', ComponentItem."No.", DemandQty, ProductionOrder."Starting Date");

        // [GIVEN] Post item stock of 2 PCS with lot no. = "L1"
        LotNo := PostItemPositiveAdjmtWithLotTracking(ComponentItem."No.", Location.Code, Bin.Code, StockQty);
        // [GIVEN] Create a warehouse pick from the production order
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);

        // [GIVEN] Set lot no. = "L1" in warehouse pick lines, set "Qty. to Handle" = 2 to pick partial quantitiy
        WarehouseActivityLine.SetRange("Item No.", ComponentItem."No.");
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo);
        WarehouseActivityLine.ModifyAll("Qty. to Handle", StockQty);

        // [WHEN] Register the warehouse pick
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityLine."Activity Type"::Pick);

        // [THEN] 2 PCS of item "CI" are tracked against the item ledger entry. 3 PCS are tracked against the purchase order.
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.",
          ReservationEntry."Reservation Status"::Tracking, DemandQty - StockQty, '');
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.",
          ReservationEntry."Reservation Status"::Surplus, StockQty, '');
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Item Ledger Entry", 0, '', ReservationEntry."Reservation Status"::Tracking, StockQty, LotNo);
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure ReservEntryUpdatedAfterChangingComponentQtyAndPicking()
    var
        Location: Record Location;
        Bin: Record Bin;
        ComponentItem: Record Item;
        ProductionOrder: Record "Production Order";
        PurchaseHeader: Record "Purchase Header";
        ReservationEntry: Record "Reservation Entry";
        DemandQty: Decimal;
        StockQty: Decimal;
        LotNo: Code[50];
    begin
        // [FEATURE] [Item Tracking] [Order Tracking] [Pick] [Production]
        // [SCENARIO 201717] Reservation entries should be updated when a warehouse pick created from production component is registered after changing component quantity, and initial quantity was picked

        Initialize();

        // [GIVEN] Location with shipment and pick required
        CreateComponentsLocationWithBin(Location, Bin);

        // [GIVEN] Lot tracked item "CI" with order tracking enabled
        CreateTrackedItem(ComponentItem);

        // [GIVEN] Production order producing an item "PI" that includes "CI" as a component. Quantity to produce is 30.
        DemandQty := LibraryRandom.RandInt(30);
        StockQty := LibraryRandom.RandIntInRange(70, 100);
        CreateProductionOrderWithComponent(ProductionOrder, ComponentItem."No.", Location.Code, Bin.Code, DemandQty);

        // [GIVEN] Purchase order for component item "CI". Quantity = 30
        CreatePurchaseOrderUpdateReceiptDate(PurchaseHeader, Location.Code, '', ComponentItem."No.", DemandQty, WorkDate() - 5);
        // [GIVEN] Post item stock of 70 PCS with lot no. = "L1"
        LotNo := PostItemPositiveAdjmtWithLotTracking(ComponentItem."No.", Location.Code, Bin.Code, StockQty);

        // [GIVEN] Create and register a warehouse pick from the production order
        CreateAndRegisterWhsePickFromProduction(ProductionOrder, LotNo);

        // [GIVEN] Set "Quantity per" = 2 in production order component. This will double the total demand for the production order.
        UpdateQtyPerInProdOrderComponent(ProductionOrder.Status, ProductionOrder."No.", 2);

        // [GIVEN] Create a warehouse pick from the production order
        // [WHEN] Register the warehouse pick
        CreateAndRegisterWhsePickFromProduction(ProductionOrder, LotNo);

        // [THEN] Surplus quantity on item ledger is 10, surplus quantity on purchase order is 30
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Item Ledger Entry", 0, '', ReservationEntry."Reservation Status"::Surplus,
          StockQty - DemandQty * 2, LotNo);
        VerifyReservationEntry(
          ComponentItem."No.", DATABASE::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.",
          ReservationEntry."Reservation Status"::Surplus, DemandQty, '');

        // [THEN] 60 PCS of item "CI" are tracked against item ledger with lot no. "L1"
        VerifyReservationQuantity(
          ReservationEntry."Reservation Status"::Tracking, DATABASE::"Prod. Order Component", ProductionOrder.Status.AsInteger(), ProductionOrder."No.",
          LotNo, -DemandQty * 2);
        VerifyReservationQuantity(
          ReservationEntry."Reservation Status"::Tracking, DATABASE::"Item Ledger Entry", 0, '', LotNo, DemandQty * 2);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure WhseJournalNotOpenedIfUserNotSetAsWhseEmployee()
    var
        Location: array[3] of Record Location;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Warehouse Employee] [UT]
        // [SCENARIO 223342] Warehouse Journal cannot be opened if the current user is not set as warehouse employee.
        Initialize();

        // [GIVEN] 3 Locations -  basic "Blue", "Silver" with mandatory bin, "White" with directed put-away and pick.
        // [GIVEN] No warehouse employee is set.
        CreateLocationsArray(Location);

        // [GIVEN] Warehouse Journal Batch for location "White".
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location[3].Code);

        // [WHEN] Open Warehouse Journal at "White".
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
        asserterror WarehouseJournalLine.OpenJnl(WarehouseJournalBatch.Name, Location[3].Code, WarehouseJournalLine);

        // [THEN] Error is thrown.
        Assert.ExpectedError(StrSubstNo(DefaultLocationNotDirectedPutawayPickErr, UserId));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerNo')]
    procedure WhseJournalNotOpenedIfWhseEmployeeLocationIsNotDirectPutAwayAndPickup()
    var
        Location: array[3] of Record Location;
        LocalWarehouseEmployee: Record "Warehouse Employee";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Warehouse Employee] [UT]
        // [SCENARIO 223342] Warehouse Journal cannot be opened if location within warehouse employee is not directed put-away and pick.
        Initialize();
        LocalWarehouseEmployee.SetRange("User ID", UserId);
        LocalWarehouseEmployee.DeleteAll(true); //Remove all the unwanted warehouse employee locations for this test.
        Commit();

        // [GIVEN] 3 Locations -  "Blue", "Silver" and "White" without directed put-away and pick.
        // [GIVEN] Current user is set as warehouse employee at "Blue" (default), 'silver" and "White".
        LibraryWarehouse.CreateLocation(Location[1]);
        LibraryWarehouse.CreateLocation(Location[2]);
        LibraryWarehouse.CreateLocation(Location[3]);
        LibraryWarehouse.CreateWarehouseEmployee(LocalWarehouseEmployee, Location[1].Code, true);
        LibraryWarehouse.CreateWarehouseEmployee(LocalWarehouseEmployee, Location[2].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(LocalWarehouseEmployee, Location[3].Code, false);

        // [WHEN] Open Warehouse Journal when all the locations for warehouse employee are not directed put-away and pick.
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);

        // [WHEN] Open Warehouse Journal Line with empty batch and location.
        asserterror InvokeOpenWarehouseJournal(WarehouseJournalLine, WarehouseJournalTemplate.Name, '', '');

        // [THEN] Error is thrown.
        Assert.ExpectedError(STRSUBSTNO(DefaultLocationNotDirectedPutawayPickErr, USERID));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseJournalOpenedIfUserSetAsWhseEmployeeAtDefaultFullWMSLocation()
    var
        Location: array[3] of Record Location;
        WhseEmployee: Record "Warehouse Employee";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Warehouse Employee] [UT]
        // [SCENARIO 223342] Warehouse Journal is opened at default directed put-away and pick location defined for the current user in warehouse employee setup.
        Initialize();

        // [GIVEN] 3 Locations -  basic "Blue", "Silver" with mandatory bin, "White" with directed put-away and pick.
        // [GIVEN] Current user is set as warehouse employee at "Blue" and "White" (default).
        CreateLocationsArray(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[1].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[3].Code, true);

        // [GIVEN] Warehouse Journal Batch for location "White".
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location[3].Code);

        // [WHEN] Open Warehouse Journal at "Blue".
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
        WarehouseJournalLine.OpenJnl(WarehouseJournalBatch.Name, Location[1].Code, WarehouseJournalLine);

        // [THEN] Warehouse Journal at location "White" is shown.
        WarehouseJournalLine.FilterGroup(2);
        Assert.AreEqual(Location[3].Code, WarehouseJournalLine.GetFilter("Location Code"), WrongWhseJournalBatchOpenedErr);

        WarehouseJournalTemplate.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseJournalBatchCreatedAndOpenedAtDefaultFullWMSLocation()
    var
        Location: array[3] of Record Location;
        WhseEmployee: Record "Warehouse Employee";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Warehouse Employee] [Warehouse Journal Batch] [UT]
        // [SCENARIO 223342] New Warehouse Journal Batch is created and Warehouse Journal with this batch is opened at default directed put-away and pick location defined for the current user.
        Initialize();

        // [GIVEN] 3 Locations -  basic "Blue", "Silver" with mandatory bin, "White" with directed put-away and pick.
        // [GIVEN] Current user is set as warehouse employee at "White" (default).
        CreateLocationsArray(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[3].Code, true);

        // [GIVEN] No Warehouse Journal Batch exists for "White".
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);

        // [WHEN] Open Warehouse Journal at "White".
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
        WarehouseJournalLine.OpenJnl(WarehouseJournalBatch.Name, Location[3].Code, WarehouseJournalLine);

        // [THEN] Warehouse Journal Batch for "White" is created.
        WarehouseJournalBatch.SetRange("Journal Template Name", WarehouseJournalTemplate.Name);
        WarehouseJournalBatch.SetRange("Location Code", Location[3].Code);
        Assert.RecordIsNotEmpty(WarehouseJournalBatch);

        // [THEN] Warehouse Journal at location "White" is shown.
        WarehouseJournalLine.FilterGroup(2);
        Assert.AreEqual(Location[3].Code, WarehouseJournalLine.GetFilter("Location Code"), WrongWhseJournalBatchOpenedErr);

        WarehouseJournalTemplate.Delete();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCreationWorksheetNotOpenedIfUserNotSetAsWhseEmployee()
    var
        Location: array[3] of Record Location;
        BinCreationWkshTemplate: Record "Bin Creation Wksh. Template";
        BinCreationWkshName: Record "Bin Creation Wksh. Name";
        BinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
    begin
        // [FEATURE] [Warehouse Employee] [Bin Creation Worksheet] [UT]
        // [SCENARIO 223342] Bin Creation Worksheet cannot be opened if the current user is not set as warehouse employee.
        Initialize();

        // [GIVEN] 3 Locations -  basic "Blue", "Silver" with mandatory bin, "White" with directed put-away and pick.
        // [GIVEN] No warehouse employee is set.
        CreateLocationsArray(Location);

        // [GIVEN] Bin Creation Worksheet Name for location "Silver".
        CreateBinCreationWkshTemplate(BinCreationWkshTemplate);
        CreateBinCreationWkshName(BinCreationWkshName, BinCreationWkshTemplate.Name, Location[2].Code);

        // [WHEN] Open Bin Creation Worksheet at "Silver".
        BinCreationWorksheetLine.SetRange("Worksheet Template Name", BinCreationWkshTemplate.Name);
        asserterror BinCreationWorksheetLine.OpenWksh(BinCreationWkshName.Name, Location[2].Code, BinCreationWorksheetLine);

        // [THEN] Error is thrown.
        Assert.ExpectedError(StrSubstNo(UserIsNotWhseEmployeeErr, UserId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCreationWorksheetNotOpenedIfUserNotSetAsWhseEmployeeAtWMSLocation()
    var
        Location: array[3] of Record Location;
        WhseEmployee: Record "Warehouse Employee";
        BinCreationWkshTemplate: Record "Bin Creation Wksh. Template";
        BinCreationWkshName: Record "Bin Creation Wksh. Name";
        BinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
    begin
        // [FEATURE] [Warehouse Employee] [Bin Creation Worksheet] [UT]
        // [SCENARIO 223342] Bin Creation Worksheet cannot be opened if location with mandatory bin is not defined for the current user in warehouse employee setup.
        Initialize();

        // [GIVEN] 3 Locations -  basic "Blue", "Silver" with mandatory bin, "White" with directed put-away and pick.
        // [GIVEN] Current user is set as warehouse employee at "Blue".
        CreateLocationsArray(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[1].Code, false);

        // [GIVEN] Bin Creation Worksheet Name for location "Silver".
        CreateBinCreationWkshTemplate(BinCreationWkshTemplate);
        CreateBinCreationWkshName(BinCreationWkshName, BinCreationWkshTemplate.Name, Location[2].Code);

        // [WHEN] Open Bin Creation Worksheet at "Silver".
        BinCreationWorksheetLine.SetRange("Worksheet Template Name", BinCreationWkshTemplate.Name);
        asserterror BinCreationWorksheetLine.OpenWksh(BinCreationWkshName.Name, Location[2].Code, BinCreationWorksheetLine);

        // [THEN] Error is thrown.
        Assert.ExpectedError(StrSubstNo(UserIsNotWhseEmployeeAtWMSLocationErr, UserId));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCreationWorksheetOpenedIfUserSetAsWhseEmployeeAtWMSLocation()
    var
        Location: array[3] of Record Location;
        WhseEmployee: Record "Warehouse Employee";
        BinCreationWkshTemplate: Record "Bin Creation Wksh. Template";
        BinCreationWkshName: Record "Bin Creation Wksh. Name";
        BinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
    begin
        // [FEATURE] [Warehouse Employee] [Bin Creation Worksheet] [UT]
        // [SCENARIO 223342] Bin Creation Worksheet is opened at location with mandatory bin defined for the current user in warehouse employee setup.
        Initialize();

        // [GIVEN] 3 Locations -  basic "Blue", "Silver" with mandatory bin, "White" with directed put-away and pick.
        // [GIVEN] Current user is set as warehouse employee at "Blue" and "Silver".
        CreateLocationsArray(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[1].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[2].Code, false);

        // [GIVEN] Bin Creation Worksheet Name for location "Silver".
        CreateBinCreationWkshTemplate(BinCreationWkshTemplate);
        CreateBinCreationWkshName(BinCreationWkshName, BinCreationWkshTemplate.Name, Location[2].Code);

        // [WHEN] Open Bin Creation Worksheet at "Blue".
        BinCreationWorksheetLine.SetRange("Worksheet Template Name", BinCreationWkshTemplate.Name);
        BinCreationWorksheetLine.OpenWksh(BinCreationWkshName.Name, Location[1].Code, BinCreationWorksheetLine);

        // [THEN] Bin Creation Worksheet at "Silver" is shown.
        BinCreationWorksheetLine.FilterGroup(2);
        Assert.AreEqual(Location[2].Code, BinCreationWorksheetLine.GetFilter("Location Code"), WrongBinCreationWkshOpenedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCreationWorksheetCreatedAndOpenedAtWMSLocation()
    var
        Location: array[3] of Record Location;
        WhseEmployee: Record "Warehouse Employee";
        BinCreationWkshTemplate: Record "Bin Creation Wksh. Template";
        BinCreationWkshName: Record "Bin Creation Wksh. Name";
        BinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
    begin
        // [FEATURE] [Warehouse Employee] [Bin Creation Worksheet] [UT]
        // [SCENARIO 223342] New Bin Creation Worksheet Name is created and Bin Creation Worksheet with this Name is opened at location with mandatory bin defined for the current user.
        Initialize();

        // [GIVEN] 3 Locations -  basic "Blue", "Silver" with mandatory bin, "White" with directed put-away and pick.
        // [GIVEN] Current user is set as warehouse employee at "Silver".
        CreateLocationsArray(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[2].Code, false);

        // [GIVEN] No Bin Creation Worksheet Name exists for "Silver".
        CreateBinCreationWkshTemplate(BinCreationWkshTemplate);

        // [WHEN] Open Bin Creation Worksheet at "Silver".
        BinCreationWorksheetLine.SetRange("Worksheet Template Name", BinCreationWkshTemplate.Name);
        BinCreationWorksheetLine.OpenWksh(BinCreationWkshName.Name, Location[2].Code, BinCreationWorksheetLine);

        // [THEN] Bin Creation Worksheet Name is created for "Silver".
        BinCreationWkshName.SetRange("Worksheet Template Name", BinCreationWkshTemplate.Name);
        BinCreationWkshName.SetRange("Location Code", Location[2].Code);
        Assert.RecordIsNotEmpty(BinCreationWkshName);

        // [THEN] Bin Creation Worksheet at "Silver" is shown.
        BinCreationWorksheetLine.FilterGroup(2);
        Assert.AreEqual(Location[2].Code, BinCreationWorksheetLine.GetFilter("Location Code"), WrongBinCreationWkshOpenedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCreationWorksheetUsesSpecialEquipmentCodeFromZone()
    var
        Location: array[3] of Record Location;
        Zone: array[3] of Record Zone;
        SpecialEquipment: Record "Special Equipment";
        WhseEmployee: Record "Warehouse Employee";
        BinCreationWkshTemplate: Record "Bin Creation Wksh. Template";
        BinCreationWkshName: array[3] of Record "Bin Creation Wksh. Name";
        BinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
    begin
        // [FEATURE] [Warehouse Employee] [Bin Creation Worksheet] [Special Equipment] [UT]
        // [SCENARIO ] Bin Creation Worksheet copies the 'Special Equipment Code' from the Zone.
        Initialize();

        // [GIVEN] Special equipment 
        if not SpecialEquipment.FindFirst() then begin
            SpecialEquipment.Init();
            SpecialEquipment.Code := LibraryUtility.GenerateRandomCode(SpecialEquipment.FieldNo(Code), Database::"Special Equipment");
            SpecialEquipment.Description := LibraryUtility.GenerateRandomText(MaxStrLen(SpecialEquipment.Description));
            SpecialEquipment.Insert(true);
        end;

        // [GIVEN] 3 Locations -  basic "Blue", "Silver" with mandatory bin, "White" with directed put-away and pick.
        // [GIVEN] Current user is set as warehouse employee at "Blue", "Silver" and "White".
        CreateLocationsArray(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[1].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[2].Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WhseEmployee, Location[3].Code, false);

        // [GIVEN] Each location has a zone defined with the special equipment code
        LibraryWarehouse.CreateZone(Zone[1], '', Location[1].Code, '', '', SpecialEquipment.Code, 0, false);
        LibraryWarehouse.CreateZone(Zone[2], '', Location[2].Code, '', '', SpecialEquipment.Code, 0, false);
        LibraryWarehouse.CreateZone(Zone[3], '', Location[3].Code, '', '', SpecialEquipment.Code, 0, false);

        // [WHEN] Bin Creation Worksheet Name for location "Blue".
        CreateBinCreationWkshTemplate(BinCreationWkshTemplate);
        commit();

        // [THEN] Error is thrown
        asserterror CreateBinCreationWkshName(BinCreationWkshName[1], BinCreationWkshTemplate.Name, Location[1].Code);
        Assert.ExpectedTestFieldError(Location[1].FieldCaption("Bin Mandatory"), Format(false));

        // [GIVEN] WorksheetNames for template and location combination
        CreateBinCreationWkshName(BinCreationWkshName[2], BinCreationWkshTemplate.Name, Location[2].Code);
        CreateBinCreationWkshName(BinCreationWkshName[3], BinCreationWkshTemplate.Name, Location[3].Code);

        // [GIVEN] Open Bin Creation Worksheet at "Silver".
        BinCreationWorksheetLine.SetRange("Worksheet Template Name", BinCreationWkshTemplate.Name);
        BinCreationWorksheetLine.OpenWksh(BinCreationWkshName[2].Name, Location[2].Code, BinCreationWorksheetLine);

        // [WHEN] Zone is selected on the Bin Cretion Worksheet Line
        BinCreationWorksheetLine.Validate(Type, BinCreationWorksheetLine.Type::Bin);
        BinCreationWorksheetLine.Validate("Bin Code", LibraryUtility.GenerateRandomCode(BinCreationWorksheetLine.FieldNo("Bin Code"), Database::"Bin Creation Worksheet Line"));
        BinCreationWorksheetLine.Validate("Location Code", Location[2].Code);
        BinCreationWorksheetLine.Validate("Zone Code", Zone[2].Code);

        // [THEN] Special equipment code is copied from zone
        BinCreationWorksheetLine.TestField("Special Equipment Code", SpecialEquipment.Code);

        // [GIVEN] Open Bin Creation Worksheet at "White".
        Clear(BinCreationWorksheetLine);
        BinCreationWorksheetLine.SetRange("Worksheet Template Name", BinCreationWkshTemplate.Name);
        BinCreationWorksheetLine.OpenWksh(BinCreationWkshName[3].Name, Location[3].Code, BinCreationWorksheetLine);

        // [WHEN] Zone is selected on the Bin Cretion Worksheet Line
        BinCreationWorksheetLine.Validate(Type, BinCreationWorksheetLine.Type::Bin);
        BinCreationWorksheetLine.Validate("Bin Code", LibraryUtility.GenerateRandomCode(BinCreationWorksheetLine.FieldNo("Bin Code"), Database::"Bin Creation Worksheet Line"));
        BinCreationWorksheetLine.Validate("Location Code", Location[3].Code);
        BinCreationWorksheetLine.Validate("Zone Code", Zone[3].Code);

        // [THEN] Special equipment code is copied from zone
        BinCreationWorksheetLine.TestField("Special Equipment Code", SpecialEquipment.Code);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustmentBinValidatedAsFromBinCodeForPositiveAdjustment()
    var
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Adjustment Bin] [UT]
        // [SCENARIO 230095] It should be possbile to enter adjustment bin in the field "From Bin Code" of the warehouse journal for an entry of type "Positive Adjustment"

        Initialize();

        Bin.Get(LocationWhite.Code, LocationWhite."Adjustment Bin Code");
        MockBinContent(Bin);
        MockWarehouseJournalLine(WarehouseJournalLine, LocationWhite.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.");

        WarehouseJournalLine.Validate("From Bin Code", LocationWhite."Adjustment Bin Code");
        WarehouseJournalLine.TestField("From Zone Code", Bin."Zone Code");

        asserterror WarehouseJournalLine.Validate("To Bin Code", LocationWhite."Adjustment Bin Code");
        Assert.ExpectedError(BinMustNotBeAdjustmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AdjustmentBinValidatedAsToBinCodeForNegativeAdjustment()
    var
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Adjustment Bin] [UT]
        // [SCENARIO 230095] It should be possbile to enter adjustment bin in the field "To Bin Code" of the warehouse journal for an entry of type "Negative Adjustment"

        Initialize();

        Bin.Get(LocationWhite.Code, LocationWhite."Adjustment Bin Code");
        MockBinContent(Bin);
        MockWarehouseJournalLine(WarehouseJournalLine, LocationWhite.Code, WarehouseJournalLine."Entry Type"::"Negative Adjmt.");

        WarehouseJournalLine.Validate("To Bin Code", LocationWhite."Adjustment Bin Code");
        WarehouseJournalLine.TestField("To Zone Code", Bin."Zone Code");

        asserterror WarehouseJournalLine.Validate("From Bin Code", LocationWhite."Adjustment Bin Code");
        Assert.ExpectedError(BinMustNotBeAdjustmentErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ValidationFailedForAdjustmentBinEntryTypeMovement()
    var
        Bin: Record Bin;
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Adjustment Bin] [UT]
        // [SCENARIO 230095] It should not be possbile to enter adjustment bin in neither "From Bin Code" nor "To Bon Code" of the warehouse journal for an entry of type "Movement"

        Initialize();

        Bin.Get(LocationWhite.Code, LocationWhite."Adjustment Bin Code");
        MockBinContent(Bin);
        MockWarehouseJournalLine(WarehouseJournalLine, LocationWhite.Code, WarehouseJournalLine."Entry Type"::Movement);

        asserterror WarehouseJournalLine.Validate("From Bin Code", LocationWhite."Adjustment Bin Code");
        Assert.ExpectedError(BinMustNotBeAdjustmentErr);
        asserterror WarehouseJournalLine.Validate("To Bin Code", LocationWhite."Adjustment Bin Code");
        Assert.ExpectedError(BinMustNotBeAdjustmentErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure WhseLotReclassficationDimensionsInheritedFromInboundItemLedgEntry()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        LotNo: Code[50];
        NewLotNo: Code[50];
        DimSetID: Integer;
    begin
        // [FEATURE] [Whse. Reclassification Journal] [Item Tracking]
        // [SCENARIO 272025] When item tracking info is changed via warehouse reclassification journal, dimension values in item reclassification entries are inherited from the initial ILE

        Initialize();

        // [GIVEN] Item tracked by lot No.
        CreateItemWithTrackingCode(Item, false, true);
        LotNo := LibraryUtility.GenerateGUID();
        NewLotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Post item stock on a "directed put-away and pick" location, assign dimensions to the inventory operation
        DimSetID := CreateDimensionSet();
        LibraryWarehouse.FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 1);
        UpdateWarehouseStockOnBinWithLotAndDimensions(Item, Bin, LotNo, 1, DimSetID);

        // [WHEN] Change lot no. on the warehouse entry via warehouse reclassification journal
        ReclassifyLotNoOnWarehouse(LocationWhite.Code, Zone.Code, Bin.Code, Item."No.", 1, LotNo, NewLotNo);

        // [THEN] Dimension values in the itventory reclassification entries are inherited from the initial inbound entry
        VerifyItemLedgerEntryDimensions(Item."No.", DimSetID);
        VerifyValueEntryDimensions(Item."No.", DimSetID);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure WhseLotReclassficationDifferentDimSetsDimensionsInheritedFromInboundItemLedgEntries()
    var
        Item: Record Item;
        Zone: Record Zone;
        Bin: Record Bin;
        LotNo: Code[50];
        NewLotNo: Code[50];
        DimSetID: array[2] of Integer;
    begin
        // [FEATURE] [Whse. Reclassification Journal] [Item Tracking]
        // [SCENARIO 272025] When item tracking info is changed via whse. reclassification journal, dimension values in item reclassification entries are inherited from the initial ILE. Test for ledger entries wit different dim. sets

        Initialize();

        // [GIVEN] Item tracked by lot No.
        CreateItemWithTrackingCode(Item, false, true);
        LotNo := LibraryUtility.GenerateGUID();
        NewLotNo := LibraryUtility.GenerateGUID();

        // [GIVEN] Post item stock on a "directed put-away and pick" location. Posting in two separate entries, assign different dimensions to each item journal line
        DimSetID[1] := CreateDimensionSet();
        DimSetID[2] := CreateDimensionSet();

        LibraryWarehouse.FindZone(Zone, LocationWhite.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, LocationWhite.Code, Zone.Code, 1);

        UpdateWarehouseStockOnBinWithLotAndDimensions(Item, Bin, LotNo, 1, DimSetID[1]);
        UpdateWarehouseStockOnBinWithLotAndDimensions(Item, Bin, LotNo, 1, DimSetID[2]);

        // [WHEN] Change lot no. on the warehouse entry via warehouse reclassification journal
        ReclassifyLotNoOnWarehouse(LocationWhite.Code, Zone.Code, Bin.Code, Item."No.", 2, LotNo, NewLotNo);

        // [THEN] Dimension values in the itventory reclassification entries are inherited from the initial inbound entries
        VerifyItemLedgerEntryDimensions(Item."No.", DimSetID[1]);
        VerifyItemLedgerEntryDimensions(Item."No.", DimSetID[2]);
        VerifyValueEntryDimensions(Item."No.", DimSetID[1]);
        VerifyValueEntryDimensions(Item."No.", DimSetID[2]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSelectToBinCodeOnWhseJournalLineIfAdjustmentBinDoesNotExist()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        AdjustmentBin: Record Bin;
        PickBin: Record Bin;
        BinContent: Record "Bin Content";
        DummyWarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Adjustment Bin] [UT]
        // [SCENARIO 280195] A user cannot set Bin Code on warehouse journal line for positive adjustment if the adjustment bin does not exist.
        Initialize();

        // [GIVEN] Location with directed put-away and pick.
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Adjustment bin is deleted.
        AdjustmentBin.Get(Location.Code, Location."Adjustment Bin Code");
        AdjustmentBin.Delete(true);

        // [GIVEN] Bin "B" on pick zone.
        FindBin(PickBin, Location.Code, true);
        LibraryWarehouse.CreateBinContent(
          BinContent, Location.Code, PickBin."Zone Code", PickBin.Code, LibraryInventory.CreateItemNo(), '', '');

        // [GIVEN] Initialize warehouse journal line for positive adjustment.
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, DummyWarehouseJournalTemplate.Type::Item, Location.Code);
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Journal Template Name" := WarehouseJournalBatch."Journal Template Name";
        WarehouseJournalLine."Journal Batch Name" := WarehouseJournalBatch.Name;
        WarehouseJournalLine."Location Code" := Location.Code;
        WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Positive Adjmt.";

        // [WHEN] Set Bin Code = "B" on the warehouse journal line.
        asserterror WarehouseJournalLine.Validate("Bin Code", PickBin.Code);

        // [THEN] An error message is thrown, reading that the adjustment bin does not exist at location.
        Assert.ExpectedErrorCannotFind(Database::Bin);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CannotSelectFromBinCodeOnWhseJournalLineIfAdjustmentBinDoesNotExist()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        AdjustmentBin: Record Bin;
        PickBin: Record Bin;
        BinContent: Record "Bin Content";
        DummyWarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [Adjustment Bin] [UT]
        // [SCENARIO 280195] A user cannot set Bin Code on warehouse journal line for negative adjustment if the adjustment bin does not exist.
        Initialize();

        // [GIVEN] Location with directed put-away and pick.
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);

        // [GIVEN] Adjustment bin is deleted.
        AdjustmentBin.Get(Location.Code, Location."Adjustment Bin Code");
        AdjustmentBin.Delete(true);

        // [GIVEN] Bin "B" on pick zone.
        FindBin(PickBin, Location.Code, true);
        LibraryWarehouse.CreateBinContent(
          BinContent, Location.Code, PickBin."Zone Code", PickBin.Code, LibraryInventory.CreateItemNo(), '', '');

        // [GIVEN] Initialize warehouse journal line for negative adjustment.
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, DummyWarehouseJournalTemplate.Type::Item, Location.Code);
        WarehouseJournalLine.Init();
        WarehouseJournalLine."Journal Template Name" := WarehouseJournalBatch."Journal Template Name";
        WarehouseJournalLine."Journal Batch Name" := WarehouseJournalBatch.Name;
        WarehouseJournalLine."Location Code" := Location.Code;
        WarehouseJournalLine."Entry Type" := WarehouseJournalLine."Entry Type"::"Negative Adjmt.";
        WarehouseJournalLine.Quantity := -LibraryRandom.RandInt(10);

        // [WHEN] Set "Bin Code" = "B" on the warehouse journal line.
        asserterror WarehouseJournalLine.Validate("Bin Code", PickBin.Code);

        // [THEN] An error message is thrown, reading that the adjustment bin does not exist at location.
        Assert.ExpectedErrorCannotFind(Database::Bin);
    end;

    [Test]
    [HandlerFunctions('DummyConfirmHandler,DummyMessageHandler,WhseItemTrackingLinesPageHandlerTwoLots')]
    [Scope('OnPrem')]
    procedure CalcWhseAdjustmentOneByOneWhenMultipleAdjustmentsWithLots()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        LotNo: array[2] of Code[50];
        Index: Integer;
        WhseItemJnlEntryType: array[4] of Integer;
        ItemJnlEntryType: array[4] of Integer;
    begin
        // [FEATURE] [Calculate Whse. Adjustment]
        // [SCENARIO 300723] Item Journal Lines and Reservation Entry when repeat sequence of registering Warehouse Journal Line
        // [SCENARIO 300723] and calling Calculate Whse. Adjustment
        // Tracking Specification is used purely as buffer in this test
        Initialize();
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        InitEntryType(WhseItemJnlEntryType, 1, 0, 0, 1); // 1 = Positive, 0 = Negative Adjustment
        InitEntryType(ItemJnlEntryType, 2, 3, 3, 2); // 2 = Positive, 3 = Negative Adjustment

        // [GIVEN] Item had stock of 200 PCS: Lot "L1" with 100 PCS and "L2" with 100 PCS
        CreateWarehouseJournalBatchWithItemTemplate(WarehouseJournalBatch);
        CreateItemWithWarehouseLotTracking(Item);
        Item.SetRecFilter();
        MakeItemStock(Item, WarehouseJournalBatch, LotNo);

        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), 1, Item."No.");
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, -LibraryRandom.RandInt(10), -LibraryRandom.RandInt(10), 2, Item."No.");
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, -LibraryRandom.RandInt(10), -LibraryRandom.RandInt(10), 3, Item."No.");
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), 4, Item."No.");
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, true);

        // [WHEN] Repeating sequence of registering Warehouse Item Journal Line and calculating Whse Adjustment as follows:
        // Warehouse Item Journal Line with 10 PCS: Lot "L1" with 3 PCS and "L2" with 7 PCS register and Calculate Whse Adjustment
        // Warehouse Item Journal Line with -10 PCS: Lot "L1" with 6 PCS and "L2" with 4 PCS register and Calculate Whse Adjustment
        // Warehouse Item Journal Line with -11 PCS: Lot "L1" with 5 PCS and "L2" with 6 PCS register and Calculate Whse Adjustment
        // Warehouse Item Journal Line with 9 PCS: Lot "L1" with 4 PCS and "L2" with 5 PCS register and Calculate Whse Adjustment
        TempTrackingSpecification.FindSet();
        repeat
            Index += 1;
            RegisterWhseItemJournalLineWithTwoLots(WarehouseJournalBatch, TempTrackingSpecification, WhseItemJnlEntryType[Index]);
            LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        until TempTrackingSpecification.Next() = 0;

        // [THEN] Four Item Journal Lines are created:
        // [THEN] Positive Adjustment with 10 PCS with Reservation Entries having 3 PCS on Lot "L1" and 7 PCS on Lot "L2"
        // [THEN] Negative Adjustment with 10 PCS with Reservation Entries having -6 PCS on Lot "L1" and -4 PCS on Lot "L2"
        // [THEN] Negative Adjustment with 11 PCS with Reservation Entries having -5 PCS on Lot "L1" and -6 PCS on Lot "L2"
        // [THEN] Positive Adjustment with 9 PCS with Reservation Entries having 4 PCS on Lot "L1" and 5 PCS on Lot "L2"
        TempTrackingSpecification.FindSet();
        Clear(Index);
        repeat
            Index += 1;
            VerifyItemJnlLineAndReservationEntryQty(TempTrackingSpecification, ItemJnlEntryType[Index]);
        until TempTrackingSpecification.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('DummyConfirmHandler,DummyMessageHandler,WhseItemTrackingLinesPageHandlerTwoLots')]
    [Scope('OnPrem')]
    procedure CalcWhseAdjustmentWhenMultipleAdjustmentsEachLotAdjPositive()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        LotNo: array[2] of Code[50];
        Index: Integer;
        WhseItemJnlEntryType: array[4] of Integer;
    begin
        // [FEATURE] [Calculate Whse. Adjustment]
        // [SCENARIO 300723] Item Journal Lines and Reservation Entry when Calculate Whse. Adjustment for several Warehouse Journal Lines
        // [SCENARIO 300723] in case total adjustment for each Lot is positive
        // Tracking Specification is used purely as buffer in this test
        Initialize();
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        InitEntryType(WhseItemJnlEntryType, 1, 0, 0, 1); // 1 = Positive, 0 = Negative Adjustment

        // [GIVEN] Item had stock of 200 PCS: Lot "L1" with 100 PCS and "L2" with 100 PCS
        CreateWarehouseJournalBatchWithItemTemplate(WarehouseJournalBatch);
        CreateItemWithWarehouseLotTracking(Item);
        Item.SetRecFilter();
        MakeItemStock(Item, WarehouseJournalBatch, LotNo);

        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandIntInRange(100, 200), 1, Item."No.");
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, -LibraryRandom.RandInt(10), -LibraryRandom.RandInt(10), 2, Item."No.");
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, -LibraryRandom.RandInt(10), -LibraryRandom.RandInt(10), 3, Item."No.");
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), 4, Item."No.");
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, true);

        // [GIVEN] Registered Warehouse Item Journal Line with 100 PCS: Lot "L1" with 30 PCS and "L2" with 70 PCS
        // [GIVEN] Registered Warehouse Item Journal Line with -10 PCS: Lot "L1" with 6 PCS and "L2" with 4 PCS
        // [GIVEN] Registered Warehouse Item Journal Line with -11 PCS: Lot "L1" with 5 PCS and "L2" with 6 PCS
        // [GIVEN] Registered Warehouse Item Journal Line with 9 PCS: Lot "L1" with 4 PCS and "L2" with 5 PCS
        TempTrackingSpecification.FindSet();
        repeat
            Index += 1;
            RegisterWhseItemJournalLineWithTwoLots(WarehouseJournalBatch, TempTrackingSpecification, WhseItemJnlEntryType[Index]);
        until TempTrackingSpecification.Next() = 0;

        // [WHEN] Calculate Whse. Adjustment
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);

        // [THEN] Positive Adjustment Item Journal Line is created with 88 PCS (88 = 100 - 10 - 11 + 9)
        // [THEN] Reservation Entry for this Line and Lot "L1" has 23 PCS (23 = 30 - 6 - 5 + 4)
        // [THEN] Reservation Entry for this Line and Lot "L2" has 65 PCS (23 = 70 - 4 - 6 + 5)
        TempTrackingSpecification.FindFirst();
        TempTrackingSpecification.CalcSums("Quantity (Base)", "Qty. to Handle (Base)");
        VerifyItemJnlLineAndReservationEntryQty(TempTrackingSpecification, 2);
    end;

    [Test]
    [HandlerFunctions('DummyConfirmHandler,DummyMessageHandler,WhseItemTrackingLinesPageHandlerTwoLots')]
    [Scope('OnPrem')]
    procedure CalcWhseAdjustmentWhenMultipleAdjustmentsLotAdjPositiveAndNegative()
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
        LotNo: array[2] of Code[50];
        Index: Integer;
        WhseItemJnlEntryType: array[4] of Integer;
    begin
        // [FEATURE] [Calculate Whse. Adjustment]
        // [SCENARIO 300723] Item Journal Lines and Reservation Entry when Calculate Whse. Adjustment for several Warehouse Journal Lines
        // [SCENARIO 300723] with two lots in case total adjustment for 1st Lot is positive and for 2nd Lot is negative
        // Tracking Specification is used purely as buffer in this test
        Initialize();
        LotNo[1] := LibraryUtility.GenerateGUID();
        LotNo[2] := LibraryUtility.GenerateGUID();
        InitEntryType(WhseItemJnlEntryType, 1, 0, 0, 1); // 1 = Positive, 0 = Negative Adjustment

        // [GIVEN] Item had stock of 200 PCS: Lot "L1" with 100 PCS and "L2" with 100 PCS
        CreateWarehouseJournalBatchWithItemTemplate(WarehouseJournalBatch);
        CreateItemWithWarehouseLotTracking(Item);
        Item.SetRecFilter();
        MakeItemStock(Item, WarehouseJournalBatch, LotNo);

        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandInt(10), 1, Item."No.");
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, -LibraryRandom.RandInt(10), -LibraryRandom.RandIntInRange(100, 200), 2, Item."No.");
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, -LibraryRandom.RandInt(10), -LibraryRandom.RandInt(10), 3, Item."No.");
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, LibraryRandom.RandInt(10), LibraryRandom.RandInt(10), 4, Item."No.");
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, true);

        // [GIVEN] Registered Warehouse Item Journal Line with 73 PCS: Lot "L1" with 70 PCS and "L2" with 3 PCS
        // [GIVEN] Registered Warehouse Item Journal Line with -106 PCS: Lot "L1" with 6 PCS and "L2" with 100 PCS
        // [GIVEN] Registered Warehouse Item Journal Line with -11 PCS: Lot "L1" with 5 PCS and "L2" with 6 PCS
        // [GIVEN] Registered Warehouse Item Journal Line with 9 PCS: Lot "L1" with 4 PCS and "L2" with 5 PCS
        TempTrackingSpecification.FindSet();
        repeat
            Index += 1;
            RegisterWhseItemJournalLineWithTwoLots(WarehouseJournalBatch, TempTrackingSpecification, WhseItemJnlEntryType[Index]);
        until TempTrackingSpecification.Next() = 0;

        // [WHEN] Calculate Whse. Adjustment
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);

        // [THEN] Positive Adjustment Item Journal Line is created with 63 PCS (63 = 70 - 6 - 5 + 4)
        // [THEN] Reservation Entry for this Line and Lot "L1" has same 63 PCS
        TempTrackingSpecification.FindFirst();
        TempTrackingSpecification.CalcSums("Quantity (Base)", "Qty. to Handle (Base)");
        VerifyItemJnlLineQuantity(Item."No.", 2, Abs(TempTrackingSpecification."Quantity (Base)"));
        VerifyReservationEntryQuantity(Item."No.", LotNo[1], TempTrackingSpecification."Quantity (Base)");

        // [THEN] Negative Adjustment Item Journal Line is created with 98 PCS (98 = 3 - 100 - 6 + 5)
        // [THEN] Reservation Entry for this Line and Lot "L2" has same 98 PCS
        VerifyItemJnlLineQuantity(Item."No.", 3, Abs(TempTrackingSpecification."Qty. to Handle (Base)"));
        VerifyReservationEntryQuantity(Item."No.", LotNo[2], TempTrackingSpecification."Qty. to Handle (Base)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PredefinedWhseJournalBatchIsSelectedWhenOpenWhseJnlLineWithPredefinedBatchAndLocation()
    var
        Location: array[2] of Record "Location";
        LocalWarehouseEmployee: array[2] of Record "Warehouse Employee";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 301475] Previously used batch and location are selected when open Warehouse Journal Line page.
        Initialize();
        ResetDefaultWhseLocation();

        // [GIVEN] Warehouse Location "L1".
        // [GIVEN] Warehouse Location "L2" with "Bin Mandatory" = true and "Direct Put-away and Pick" = true.
        // [GIVEN] Warehouse Employee "E1" with default location "L1".
        // [GIVEN] Warehouse Employee "E2" with not default location "L2".
        // [GIVEN] Warehouse Journal Template "T".
        // [GIVEN] Warehouse Journal Batch "B" with "Journal Template Name" = "T".
        SetupWarehouseJournalBatchEnvironmentTwoLocations(
          Location,
          LocalWarehouseEmployee,
          WarehouseJournalTemplate,
          WarehouseJournalBatch);

        // [WHEN] Open Warehouse Journal Line with batch = "B" and location = "L2".
        InvokeOpenWarehouseJournal(WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location[2].Code);

        // [THEN] "Journal Batch Name" is filtered with "B" on Warehouse Journal Line.
        Assert.AreEqual(WarehouseJournalBatch.Name, WarehouseJournalLine.GETFILTER("Journal Batch Name"), WrongWhseJournalBatchErr);

        // [THEN] "Location Code" is filtered with "L2" on Warehouse Journal Line.
        Assert.AreEqual(Location[2].Code, WarehouseJournalLine.GETFILTER("Location Code"), WrongLocationCodeErr);

        // Tear down.
        WarehouseJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseJournalBatchWithDefaultLocationIsSelectedWhenOpenWhseJnlLineWithWithEmptyBatchAndLocation()
    var
        Location: Record "Location";
        LocalWarehouseEmployee: Record "Warehouse Employee";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 301475] Batch with default location is selected when open Warehouse Journal Line page for the first time.
        Initialize();
        ResetDefaultWhseLocation();

        // [GIVEN] Warehouse Location "L" with "Bin Mandatory" = true and "Direct Put-away and Pick" = true.
        // [GIVEN] Warehouse Employee with default location "L".
        // [GIVEN] Warehouse Journal Template "T".
        // [GIVEN] Warehouse Journal Batch "B" with "Journal Template Name" = "T".
        SetupWarehouseJournalBatchEnvironmentOneLocation(
          Location,
          LocalWarehouseEmployee,
          WarehouseJournalTemplate,
          WarehouseJournalBatch);

        // [WHEN] Open Warehouse Journal Line with empty batch and location.
        InvokeOpenWarehouseJournal(WarehouseJournalLine, WarehouseJournalTemplate.Name, '', '');

        // [THEN] "Journal Batch Name" is filtered with "B" on Warehouse Journal Line.
        Assert.AreEqual(WarehouseJournalBatch.Name, WarehouseJournalLine.GETFILTER("Journal Batch Name"), WrongWhseJournalBatchErr);

        // [THEN] "Location Code" is filtered with "L" on Warehouse Journal Line.
        Assert.AreEqual(Location.Code, WarehouseJournalLine.GETFILTER("Location Code"), WrongLocationCodeErr);

        // Tear down.
        WarehouseJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExistingWhseJournalBatchIsSelectedWhenOpenWhseJnlLineWithEmptyBatchAndLocation()
    var
        Location: array[2] of Record "Location";
        LocalWarehouseEmployee: array[2] of Record "Warehouse Employee";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 301475] First available batch and location are selected when open Warehouse Journal Line page using template where no batch has default location.
        Initialize();
        ResetDefaultWhseLocation();

        // [GIVEN] Warehouse Location "L1".
        // [GIVEN] Warehouse Location "L2" with "Bin Mandatory" = true and "Direct Put-away and Pick" = true.
        // [GIVEN] Warehouse Employee "E1" with default location "L1".
        // [GIVEN] Warehouse Employee "E2" with not default location "L2".
        // [GIVEN] Warehouse Journal Template "T".
        // [GIVEN] Warehouse Journal Batch "B" with "Journal Template Name" = "T".
        SetupWarehouseJournalBatchEnvironmentTwoLocations(
          Location,
          LocalWarehouseEmployee,
          WarehouseJournalTemplate,
          WarehouseJournalBatch);

        // [WHEN] Open Warehouse Journal Line with empty batch and location.
        InvokeOpenWarehouseJournal(WarehouseJournalLine, WarehouseJournalTemplate.Name, '', '');

        // [THEN] "Journal Batch Name" is filtered with "B" on Warehouse Journal Line.
        Assert.AreEqual(WarehouseJournalBatch.Name, WarehouseJournalLine.GETFILTER("Journal Batch Name"), WrongWhseJournalBatchErr);

        // [THEN] "Location Code" is filtered with "L2" on Warehouse Journal Line.
        Assert.AreEqual(Location[2].Code, WarehouseJournalLine.GETFILTER("Location Code"), WrongLocationCodeErr);

        // Tear down.
        WarehouseJournalTemplate.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewWhseJournalBatchIsCreatedAndSelectedWhenOpenWhseJnlLineWichEmptyBactchAndLocation()
    var
        Location: Record "Location";
        LocalWarehouseEmployee: Record "Warehouse Employee";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 301475] New batch with default location is created and selected when open Warehouse Journal Line page using template with no batches.
        Initialize();
        ResetDefaultWhseLocation();

        // [GIVEN] Warehouse Location "L" with "Bin Mandatory" = true and "Direct Put-away and Pick" = true.
        // [GIVEN] Warehouse Employee "E" with default location "L".
        SetupWarehouseJournalBatchEnvironmentNoBatch(Location, LocalWarehouseEmployee, WarehouseJournalTemplate, true);

        // [WHEN] Open Warehouse Journal Line with empty batch and location.
        InvokeOpenWarehouseJournal(WarehouseJournalLine, WarehouseJournalTemplate.Name, '', '');

        // [THEN] "Journal Batch Name" is filtered with default batch name on Warehouse Journal Line.
        Assert.AreEqual(WhseJournalBatchDefaultNameTxt, WarehouseJournalLine.GETFILTER("Journal Batch Name"), WrongWhseJournalBatchErr);

        // [THEN] "Location Code" is filtered with "L" on Warehouse Journal Line.
        Assert.AreEqual(Location.Code, WarehouseJournalLine.GETFILTER("Location Code"), WrongLocationCodeErr);

        // Tear down.
        WarehouseJournalTemplate.Delete(true);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesModalPageHandler,DummyConfirmHandler,DummyMessageHandler')]
    [Scope('OnPrem')]
    procedure CalculatingWhseAdjustmentFilteredBySerialNo()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        Zone: Record Zone;
        Bin: Record Bin;
        ItemTrackingCode: Record "Item Tracking Code";
        Item: Record Item;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        SerialNos: array[5] of Text;
        NoOfSN: Integer;
        i: Integer;
    begin
        // [FEATURE] [Warehouse Adjustment] [Warehouse Item Journal] [Item Tracking]
        // [SCENARIO 317711] Running warehouse adjustment filtered by serial nos. creates item journal for quantity and item tracking that meets the filter.
        Initialize();
        ResetDefaultWhseLocation();

        // [GIVEN] 10 serial nos.
        NoOfSN := ArrayLen(SerialNos);
        for i := 1 to NoOfSN do
            SerialNos[i] := LibraryUtility.GenerateGUID();

        // [GIVEN] Location with directed put-away and pick.
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.FindZone(Zone, Location.Code, LibraryWarehouse.SelectBinType(false, false, true, true), false);
        LibraryWarehouse.FindBin(Bin, Location.Code, Zone.Code, 1);

        // [GIVEN] Serial no. tracked item.
        LibraryItemTracking.CreateSerialItem(Item);
        ItemTrackingCode.Get(Item."Item Tracking Code");
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);

        // [GIVEN] Create whse. item journal line, quantity = 10.
        // [GIVEN] Assign serial nos. S1, S2, ..., S10.
        // [GIVEN] Register the warehouse adjustment.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name,
          Location.Code, Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", NoOfSN);

        LibraryVariableStorage.Enqueue(NoOfSN);
        for i := 1 to NoOfSN do
            LibraryVariableStorage.Enqueue(SerialNos[i]);
        WarehouseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Location.Code, false);

        // [WHEN] Calculate warehouse adjustment filtered by serial nos. "S1"|"S10".
        Item.SetFilter("Serial No. Filter", '%1|%2', SerialNos[1], SerialNos[NoOfSN]);
        Item.SetRange("Location Filter", Location.Code);
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), LibraryUtility.GenerateGUID());

        // [THEN] Item journal line for 2 pcs is created.
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, 2);

        // [THEN] Serial nos. "S1" and "S10" are assigned in the item tracking on the item journal line.
        ReservationEntry.SetRange("Source Type", DATABASE::"Item Journal Line");
        ReservationEntry.SetRange("Item No.", Item."No.");
        Assert.RecordCount(ReservationEntry, 2);
        ReservationEntry.SetRange("Serial No.", SerialNos[1]);
        Assert.RecordCount(ReservationEntry, 1);
        ReservationEntry.SetRange("Serial No.", SerialNos[NoOfSN]);
        Assert.RecordCount(ReservationEntry, 1);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhseAdjustmentOnCurrentZoneOfAdjustmentBin()
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
        OldAdjmtZone: Record Zone;
        NewAdjmtZone: Record Zone;
        AdjmtBin: Record Bin;
        Bin: Record Bin;
        Item: Record Item;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalLine: Record "Item Journal Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Warehouse Adjustment] [Adjustment Bin] [Zone]
        // [SCENARIO 329519] Warehouse adjustment takes only the current zone of the adjustment bin.
        Initialize();
        ResetDefaultWhseLocation();
        Qty := LibraryRandom.RandInt(10);

        LibraryInventory.CreateItem(Item);

        // [GIVEN] Location set up for directed put-away and pick.
        // [GIVEN] The adjustment bin is now on zone "Z1".
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        AdjmtBin.Get(Location.Code, Location."Adjustment Bin Code");
        OldAdjmtZone.Get(Location.Code, AdjmtBin."Zone Code");

        // [GIVEN] Post positive warehouse adjustment for 10 pcs using warehouse journal.
        FindBin(Bin, Location.Code, true);
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", Qty, false);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);

        // [GIVEN] Change the zone code of the adjustment bin to "Z2".
        NewAdjmtZone.SetRange("Location Code", Location.Code);
        NewAdjmtZone.SetRange("Bin Type Code", OldAdjmtZone."Bin Type Code");
        NewAdjmtZone.SetFilter(Code, '<>%1', OldAdjmtZone.Code);
        NewAdjmtZone.FindFirst();
        AdjmtBin.Find();
        AdjmtBin."Zone Code" := NewAdjmtZone.Code;
        AdjmtBin.Modify();

        // [GIVEN] Post another positive warehouse adjustment for 10 pcs.
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name",
          Bin."Location Code", Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Qty);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Location.Code, true);

        // [WHEN] Calculate warehouse adjustment in item journal.
        Item.SetRange("Location Filter", Location.Code);
        LibraryWarehouse.CalculateWhseAdjustmentItemJournal(Item, WorkDate(), '');

        // [THEN] An item journal line for 10 pcs is created.
        ItemJournalLine.SetRange("Item No.", Item."No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, Qty);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    [Scope('OnPrem')]
    procedure QtyPerUOMOnWhseItemTrackingLineFromWhseItemJournal()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        QtyPerUOM: Decimal;
    begin
        // [FEATURE] [Item Tracking] [Unit of Measure]
        // [SCENARIO 352334] "Qty. per Unit of Measure" is correctly populated on whse. item tracking line opened from whse. item journal.
        Initialize();
        QtyPerUOM := LibraryRandom.RandIntInRange(5, 10);

        // [GIVEN] Lot-tracked item with alternate unit of measure "PACK" = 5 pcs.
        CreateItemWithItemTrackingCode(Item, false, true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyPerUOM);

        // [GIVEN] Create warehouse journal line for 1 "PACK".
        FindBin(Bin, LocationWhite.Code, true);
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", 1, false);
        WarehouseJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        WarehouseJournalLine.Modify(true);

        // [WHEN] Open whse. item tracking and assign a lot no.
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Lot No");
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        WarehouseJournalLine.OpenItemTrackingLines();

        // [THEN] "Qty. per Unit of Measure" on the whse. item tracking line is equal to 5.
        WhseItemTrackingLine.SetRange("Item No.", Item."No.");
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.TestField("Qty. per Unit of Measure", QtyPerUOM);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    procedure DeleteWhseItemTrackingOnChangeItemNo()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 422043] Whse. item tracking lines are deleted when you change item no. on warehouse journal line.
        Initialize();

        CreateItemWithItemTrackingCode(Item, false, true);

        FindBin(Bin, LocationWhite.Code, true);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Lot No");
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", LibraryRandom.RandInt(10), true);

        WhseItemTrackingLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsNotEmpty(WhseItemTrackingLine);

        WarehouseJournalLine.Validate("Item No.", LibraryInventory.CreateItemNo());

        Assert.RecordIsEmpty(WhseItemTrackingLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    procedure DeleteWhseItemTrackingOnChangeVariantCode()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 422043] Whse. item tracking lines are deleted when you change variant code on warehouse journal line.
        Initialize();

        CreateItemWithItemTrackingCode(Item, false, true);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        FindBin(Bin, LocationWhite.Code, true);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Lot No");
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", LibraryRandom.RandInt(10), true);

        WhseItemTrackingLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsNotEmpty(WhseItemTrackingLine);

        WarehouseJournalLine.Validate("Variant Code", ItemVariant.Code);

        Assert.RecordIsEmpty(WhseItemTrackingLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandler')]
    procedure DeleteWhseItemTrackingOnChangeUnitOfMeasureCode()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 422043] Whse. item tracking lines are deleted when you change unit of measure code on warehouse journal line.
        Initialize();

        CreateItemWithItemTrackingCode(Item, false, true);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(2, 5));

        FindBin(Bin, LocationWhite.Code, true);

        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Lot No");
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", LibraryRandom.RandInt(10), true);

        WhseItemTrackingLine.SetRange("Item No.", Item."No.");
        Assert.RecordIsNotEmpty(WhseItemTrackingLine);

        WarehouseJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);

        Assert.RecordIsEmpty(WhseItemTrackingLine);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandlerTwoLotsAndPackages,DummyConfirmHandler,DummyMessageHandler,WhseJournalBatchesListHandler,WhseCalculateInventoryRequestPageHandler')]
    procedure VerifyWarehousePhysicalJournalLinesForWarehouseEntriesWithLotAndPackageTrackingNo()
    var
        Bin: Record Bin;
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        WhsePhysInvtJournal: TestPage "Whse. Phys. Invt. Journal";
    begin
        // [SCENARIO 455411] Verify that all Warehouse Entries are inserted in Warehouse Physical Journal when Lot and Package tracking No. are used 
        Initialize();

        // [GIVEN] Set Direct Put-away and Pick to false, except Location White
        SetDirectPutAwayOnLocation();

        // [GIVEN] Create Item Tracking Item
        CreateItemTrackingCode(ItemTrackingCode);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        // [GIVEN] Enter Tracking Information (Lot No., Package No., Qty.)        
        LibraryVariableStorage.Enqueue(4);
        EnterTrackingInfo(1, 1, 5);
        EnterTrackingInfo(1, 2, 5);
        EnterTrackingInfo(2, 1, 5);
        EnterTrackingInfo(2, 2, 5);

        // [GIVEN] Create Bin for PICK Zone
        CreateBinForPickZone(Bin, LocationWhite.Code);

        // [GIVEN] Create and Register Warehouse Journal Line
        CreateAndRegisterWarehouseJournalLine(WarehouseJournalLine, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", 20);

        // [GIVEN] Calculate and Post Warehouse Adjustment
        CalculateAndPostWhseAdjustment(Item);

        // [GIVEN] Enter Tracking Information (Lot No., Package No., Qty.)
        LibraryVariableStorage.Enqueue(1);
        EnterTrackingInfo(1, 2, 2);

        // [GIVEN] Create and Register Warehouse Journal Line
        Clear(WarehouseJournalLine);
        CreateAndRegisterWarehouseJournalLine(WarehouseJournalLine, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", -2);

        // [GIVEN] Calculate and Post Warehouse Adjustment
        CalculateAndPostWhseAdjustment(Item);

        // [WHEN] Calculate Inventory on Warehouse Physical Journal
        CalculateInventoryOnWhsePhysInvtJournalPage(WhsePhysInvtJournal, false, Item."No.", Bin."Zone Code", Bin.Code);

        // [THEN] Verify Warehouse Physical Journal Lines
        VerifyWarehousePhysicalJournalLineExist(Bin."Zone Code", Bin.Code, Item."No.", Format(1), Format(1), 5);
        VerifyWarehousePhysicalJournalLineExist(Bin."Zone Code", Bin.Code, Item."No.", Format(1), Format(2), 3);
        VerifyWarehousePhysicalJournalLineExist(Bin."Zone Code", Bin.Code, Item."No.", Format(2), Format(1), 5);
        VerifyWarehousePhysicalJournalLineExist(Bin."Zone Code", Bin.Code, Item."No.", Format(2), Format(2), 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BinCodeShouldNotFilteredOnPageBinContentSuggestedLine()
    var
        Item: Record Item;
        Bin: Record Bin;
        ItemCard: TestPage "Item Card";
        BinContentPage: TestPage "Bin Content";
    begin
        // [SCENARIO 474955] Zone Code is filtered on page Bin Content
        Initialize();

        // [GIVEN] Setup: Create Item, Create Bin Content.
        CreateItem(Item, '');
        FindBin(Bin, LocationWhite.Code, true);  // Find Bin for From Bin Code.

        // [THEN] Exercise: Open Bin Content Page from Item Card and insert new line information.
        ItemCard.OpenView();
        ItemCard.GoToRecord(Item);
        BinContentPage.Trap();
        ItemCard."&Bin Contents".Invoke();
        BinContentPage."Location Code".SetValue(Bin."Location Code");
        BinContentPage."Bin Code".SetValue(Bin.Code);

        // [WHEN] Set the current row of the test page to an empty row in a data set
        BinContentPage.New();

        // [VERIFY] Verify: Bin Code is blank on New Suggested Line, and also ensure Location Code copied from previous line
        BinContentPage."Location Code".AssertEquals(Bin."Location Code");
        BinContentPage."Bin Code".AssertEquals('');
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesZeroQtyModalPageHandler,ConfirmHandlerYesNo')]
    procedure ConfirmMessageWhenClosingWhseItemTrackingLinesWithZeroQty()
    var
        Item: Record Item;
        Bin: Record Bin;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // [SCENARIO 485654] Confirmation message when closing Whse. Item Tracking Lines page with zero qty. on one or more lines.
        Initialize();

        CreateItemWithTrackingCode(Item, false, true);
        FindBin(Bin, LocationWhite.Code, true);

        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalBatch."Template Type"::Item, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, '', Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);

        WarehouseJournalLine.OpenItemTrackingLines();

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesSerialNoPageHandler,DummyConfirmHandler,DummyMessageHandler,WhseCalculateInventoryRequestPageHandler2')]
    [Scope('OnPrem')]
    procedure CalculateInventoryShouldGiveNoErrorWhenEnterLotNoInPickForOnlySerialTrackedItem()
    var
        Item: Record Item;
        Bin: Record Bin;
        Zone: Record Zone;
        Location: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WhseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        WhseJournalTemplate: Record "Warehouse Journal Template";
        WhseJournalBatch: Record "Warehouse Journal Batch";
        WhseJournalLine: Record "Warehouse Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        SerialNo: Code[50];
        SerialNo2: Code[50];
        LotNo: Code[50];
    begin
        // [SCENARIO 481693] Adding a Lot No. to Warehouse Pick for a Serial Tracked Item causes error when Calculate Inventory in Warehouse Physical Inventory Jrl when that Serial Number is no longer there: “Qty. (Phys. Inventory) must be 0 or 1 for an Item tracked by SN
        Initialize();

        // [GIVEN] Create an Item Tracking Code with Serial Tracking.
        CreateItemTrackingCode(ItemTrackingCode, true, false);

        // [GIVEN] Create an Item & Validate Item Tracking Code & Serial Nos.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);

        // [GIVEN] Create Location with Warehouse Employee Setup.
        CreateLocationWithWarehouseEmployeeSetup(Location, WhseEmployee);

        // [GIVEN] Create a Zone for Location White.
        LibraryWarehouse.CreateZone(
            Zone,
            Zone.Code,
            Location.Code,
            LibraryWarehouse.SelectBinType(false, false, true, true),
            '',
            '',
            0,
            false);

        // [GIVEN] Create a Bin for Location White.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, Zone.Code, Zone."Bin Type Code");

        // [GIVEN] Generate & save Serial No in a Variable.
        SerialNo := Format(LibraryRandom.RandText(5));

        // [GIVEN] Generate & save Serial No 2 in a Variable.
        SerialNo2 := Format(LibraryRandom.RandText(5));

        // [GIVEN] Generate & save Lot No in a Variable.
        LotNo := Format(LibraryRandom.RandText(5));

        // [GIVEN] Create Warehouse Journal Setup.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WhseJournalTemplate, WhseJournalBatch);

        // [GIVEN] Create Warehouse Item Journal Line with Item Tracking for Serial No.
        CreateWhseJournalLineWithSerialTracking(WhseJournalBatch, Bin, Item."No.", LibraryRandom.RandInt(0), SerialNo, WorkDate());

        // [GIVEN] Register Warehouse Item Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(WhseJournalTemplate.Name, WhseJournalBatch.Name, Location.Code, false);

        // [GIVEN] Create Item Journal to Calculate Warehouse Adjustment.
        CreateItemJournalToCalculateWhseAdjustment(ItemJournalTemplate, ItemJournalBatch, Item);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create and Release Sales Order.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", Location.Code);

        // [GIVEN] Create Warehouse Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Header.
        WhseShipmentHeader.Get(
            LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
                DATABASE::"Sales Line",
                SalesHeader."Document Type".AsInteger(),
                SalesHeader."No."));

        // [GIVEN] Create Warehouse Pick.
        LibraryWarehouse.CreatePick(WhseShipmentHeader);

        // [GIVEN] Assign Serial No, Lot No & Qty to Handle in Warehouse Activity Lines.
        AssignSerialNoLotNoAndQtyToHandleInWhseActivityLines(WhseActivityLine, Item."No.", SerialNo, LotNo);

        // [GIVEN] Find Warehouse Activity Header.
        WhseActivityHeader.Get(WhseActivityHeader.Type::Pick, WhseActivityLine."No.");

        // [GIVEN] Register Warehouse Pick.
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // [GIVEN] Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WhseShipmentHeader, false);

        // [GIVEN] Open Warehouse Physical Inventory Journal Page & Calculate Inventory.
        CalculateInventoryFromWhsePhysInvJournalPage(Location.Code, Item."No.");

        // [WHEN] Find Warehouse Journal Line.
        WhseJournalLine.SetRange("Item No.", Item."No.");

        // [VERIFY] Verify No Warehouse Journal Line has been created.
        asserterror WhseJournalLine.FindFirst();

        // [GIVEN] Create Warehouse Item Journal Line with Item Tracking for Serial No 2.
        CreateWhseJournalLineWithSerialTracking(WhseJournalBatch, Bin, Item."No.", LibraryRandom.RandInt(0), SerialNo2, WorkDate());

        // [GIVEN] Register Warehouse Item Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(WhseJournalTemplate.Name, WhseJournalBatch.Name, Location.Code, false);

        // [GIVEN] Create Item Journal to Calculate Warehouse Adjustment.
        CreateItemJournalToCalculateWhseAdjustment(ItemJournalTemplate, ItemJournalBatch, Item);

        // [GIVEN] Open Warehouse Physical Inventory Journal Page & Calculate Inventory.
        CalculateInventoryFromWhsePhysInvJournalPage(Location.Code, Item."No.");

        // [WHEN] Find Warehouse Journal Line.
        WhseJournalLine.SetRange("Item No.", Item."No.");
        WhseJournalLine.FindSet();

        // [VERIFY] Verify that Calculate Inventory pulls only one Warehouse Journal Line.
        Assert.AreEqual(LibraryRandom.RandInt(0), WhseJournalLine.Count(), OnlyOneWarehouseJournalLineShouldBeCreatedErr);

        // [VERIFY] Verify that created Warehouse Journal Line has Serial No 2 & Lot No is blank.
        Assert.AreEqual(SerialNo2, WhseJournalLine."Serial No.", SerialNoMustMatchErr);
        Assert.AreEqual('', WhseJournalLine."Lot No.", LotNoMustBeBlankErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesLotNoPageHandler,DummyConfirmHandler,DummyMessageHandler,WhseCalculateInventoryRequestPageHandler2')]
    [Scope('OnPrem')]
    procedure CalculateInventoryShouldGiveNoErrorWhenEnterSerialNoInPickForOnlyLotTrackedItem()
    var
        Item: Record Item;
        Bin: Record Bin;
        Zone: Record Zone;
        Location: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WhseEmployee: Record "Warehouse Employee";
        ItemTrackingCode: Record "Item Tracking Code";
        WhseJournalTemplate: Record "Warehouse Journal Template";
        WhseJournalBatch: Record "Warehouse Journal Batch";
        WhseJournalLine: Record "Warehouse Journal Line";
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        WhseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityHeader: Record "Warehouse Activity Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        SerialNo: Code[50];
        LotNo: Code[50];
        LotNo2: Code[50];
    begin
        // [SCENARIO 481693] Adding a Lot No. to Warehouse Pick for a Serial Tracked Item causes error when Calculate Inventory in Warehouse Physical Inventory Jrl when that Serial Number is no longer there: “Qty. (Phys. Inventory) must be 0 or 1 for an Item tracked by SN
        Initialize();

        // [GIVEN] Create an Item Tracking Code with Lot Tracking.
        CreateItemTrackingCode(ItemTrackingCode, false, true);

        // [GIVEN] Create an Item & Validate Item Tracking Code & Serial Nos.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        Item.Modify(true);

        // [GIVEN] Create Location with Warehouse Employee Setup.
        CreateLocationWithWarehouseEmployeeSetup(Location, WhseEmployee);

        // [GIVEN] Create a Zone for Location White.
        LibraryWarehouse.CreateZone(
            Zone,
            Zone.Code,
            Location.Code,
            LibraryWarehouse.SelectBinType(false, false, true, true),
            '',
            '',
            0,
            false);

        // [GIVEN] Create a Bin for Location White.
        LibraryWarehouse.CreateBin(Bin, Location.Code, Bin.Code, Zone.Code, Zone."Bin Type Code");

        // [GIVEN] Generate & save Serial No in a Variable.
        SerialNo := Format(LibraryRandom.RandText(5));

        // [GIVEN] Generate & save Lot No in a Variable.
        LotNo := Format(LibraryRandom.RandText(5));

        // [GIVEN] Generate & save Lot No 2 in a Variable.
        LotNo2 := Format(LibraryRandom.RandText(5));

        // [GIVEN] Create Warehouse Journal Setup.
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WhseJournalTemplate, WhseJournalBatch);

        // [GIVEN] Create Warehouse Item Journal Line with Item Tracking for Lot No.
        CreateWhseJournalLineWithLotTracking(WhseJournalBatch, Bin, Item."No.", LibraryRandom.RandInt(0), LotNo, WorkDate());

        // [GIVEN] Register Warehouse Item Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(WhseJournalTemplate.Name, WhseJournalBatch.Name, Location.Code, false);

        // [GIVEN] Create Item Journal to Calculate Warehouse Adjustment.
        CreateItemJournalToCalculateWhseAdjustment(ItemJournalTemplate, ItemJournalBatch, Item);

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create and Release Sales Order.
        CreateAndReleaseSalesOrder(SalesHeader, SalesLine, Customer."No.", Item."No.", Location.Code);

        // [GIVEN] Create Warehouse Shipment from Sales Order.
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        // [GIVEN] Find Warehouse Shipment Header.
        WhseShipmentHeader.Get(
            LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
                DATABASE::"Sales Line",
                SalesHeader."Document Type".AsInteger(),
                SalesHeader."No."));

        // [GIVEN] Create Warehouse Pick.
        LibraryWarehouse.CreatePick(WhseShipmentHeader);

        // [GIVEN] Assign Serial No, Lot No & Qty to Handle in Warehouse Activity Lines.
        AssignSerialNoLotNoAndQtyToHandleInWhseActivityLines(WhseActivityLine, Item."No.", SerialNo, LotNo);

        // [GIVEN] Find Warehouse Activity Header.
        WhseActivityHeader.SetRange("No.", WhseActivityLine."No.");
        WhseActivityHeader.FindFirst();

        // [GIVEN] Register Warehouse Pick.
        LibraryWarehouse.RegisterWhseActivity(WhseActivityHeader);

        // [GIVEN] Post Warehouse Shipment.
        LibraryWarehouse.PostWhseShipment(WhseShipmentHeader, false);

        // [GIVEN] Open Warehouse Physical Inventory Journal Page & Calculate Inventory.
        CalculateInventoryFromWhsePhysInvJournalPage(Location.Code, Item."No.");

        // [WHEN] Find Warehouse Journal Line.
        WhseJournalLine.SetRange("Item No.", Item."No.");

        // [VERIFY] Verify No Warehouse Journal Line has been created.
        asserterror WhseJournalLine.FindFirst();

        // [GIVEN] Create Warehouse Item Journal Line with Item Tracking for Lot No 2.
        CreateWhseJournalLineWithLotTracking(WhseJournalBatch, Bin, Item."No.", LibraryRandom.RandInt(0), LotNo2, WorkDate());

        // [GIVEN] Register Warehouse Item Journal Line.
        LibraryWarehouse.RegisterWhseJournalLine(WhseJournalTemplate.Name, WhseJournalBatch.Name, Location.Code, false);

        // [GIVEN] Create Item Journal to Calculate Warehouse Adjustment.
        CreateItemJournalToCalculateWhseAdjustment(ItemJournalTemplate, ItemJournalBatch, Item);

        // [GIVEN] Open Warehouse Physical Inventory Journal Page & Calculate Inventory.
        CalculateInventoryFromWhsePhysInvJournalPage(Location.Code, Item."No.");

        // [WHEN] Find Warehouse Journal Line.
        WhseJournalLine.SetRange("Item No.", Item."No.");
        WhseJournalLine.FindSet();

        // [VERIFY] Verify that Calculate Inventory pulls only one Warehouse Journal Line.
        Assert.AreEqual(LibraryRandom.RandInt(0), WhseJournalLine.Count(), OnlyOneWarehouseJournalLineShouldBeCreatedErr);

        // [VERIFY] Verify that created Warehouse Journal Line has Lot No 2 & Serial No is blank.
        Assert.AreEqual(LotNo2, WhseJournalLine."Lot No.", LotNoMustMatchErr);
        Assert.AreEqual('', WhseJournalLine."Serial No.", SerialNoMustBeBlankErr);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandlerWithLotsAndExpirationDate,DummyConfirmHandler,DummyMessageHandler,WhseJournalBatchesListHandler,WhseCalculateInventoryRequestPageHandler')]
    procedure WarehousePhysicalJournalLinesForWarehouseEntriesWithLotAndExpirationDateTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        WhsePhysInvtJournal: TestPage "Whse. Phys. Invt. Journal";
        ExpirationDate: Date;
    begin
        // [SCENARIO 489308] There is no validation for Lot Number with Expiration on Warehouse Physical Journal when manually entered with quantity, which leads to a Lot Number with multiple Expiration Dates in the warehouse.
        Initialize();

        // [GIVEN] Set Direct Put-away and Pick to false, except Location White
        SetDirectPutAwayOnLocation();

        // [GIVEN] Create Item Tracking Item
        CreateItemTrackingCode(ItemTrackingCode);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        // [GIVEN] Enter Tracking Information (Lot No., Package No., Qty., Expiration Date)
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        EnterTrackingInfoWithExpirationDate(1, 1, 1, ExpirationDate);

        // [GIVEN] Create Bin for PICK Zone
        CreateBinForPickZone(Bin, LocationWhite.Code);

        // [GIVEN] Create and Register Warehouse Journal Line
        CreateAndRegisterWarehouseJournalLineWithExpirationDate(WarehouseJournalLine, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", 1);

        // [GIVEN] Calculate and Post Warehouse Adjustment
        CalculateAndPostWhseAdjustment(Item);

        // [WHEN] Calculate Inventory on Warehouse Physical Journal
        CalculateInventoryOnWhsePhysInvtJournalPage(WhsePhysInvtJournal, false, Item."No.", Bin."Zone Code", Bin.Code);

        // [THEN] Verify Warehouse Physical Journal Line
        VerifyExpirationDateOnWarehousePhysicalJournalLine(Bin."Zone Code", Bin.Code, Item."No.", Format(1), ExpirationDate);
    end;

    [Test]
    [HandlerFunctions('WhseItemTrackingLinesPageHandlerWithLotsAndExpirationDate,DummyConfirmHandler,DummyMessageHandler')]
    procedure ManualWarehousePhysicalJournalLinesForWarehouseEntriesWithLotAndExpirationDateTracking()
    var
        Bin: Record Bin;
        Item: Record Item;
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemTrackingCode: Record "Item Tracking Code";
        ExpirationDate: Date;
    begin
        // [SCENARIO 489308] There is no validation for Lot Number with Expiration on Warehouse Physical Journal when manually entered with quantity, which leads to a Lot Number with multiple Expiration Dates in the warehouse.
        Initialize();

        // [GIVEN] Set Direct Put-away and Pick to false, except Location White
        SetDirectPutAwayOnLocation();

        // [GIVEN] Create Item Tracking Item
        CreateItemTrackingCode(ItemTrackingCode);
        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);

        // [GIVEN] Enter Tracking Information (Lot No., Package No., Qty., Expiration Date)
        ExpirationDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate());
        EnterTrackingInfoWithExpirationDate(1, 1, 1, ExpirationDate);

        // [GIVEN] Create Bin for PICK Zone
        CreateBinForPickZone(Bin, LocationWhite.Code);

        // [GIVEN] Create and Register Warehouse Journal Line
        CreateAndRegisterWarehouseJournalLineWithExpirationDate(WarehouseJournalLine, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", 1);

        // [GIVEN] Calculate and Post Warehouse Adjustment
        CalculateAndPostWhseAdjustment(Item);

        // [WHEN] Manually Mock the Warehouse Journal Line
        MockWarehouseJournalLine(WarehouseJournalLine, Bin."Location Code", WarehouseJournalLine."Entry Type"::"Positive Adjmt.");

        // [VERIFY] Verify: Expiration Date Populated on Warehouse Physical Journal Line when correct Lot No. validated
        WarehouseJournalLine.Validate("Lot No.", Format(1));
        Assert.IsTrue((WarehouseJournalLine."Expiration Date" = ExpirationDate), '');

        // [VERIFY] Verify: Expiration Date set to 0D on Warehouse Physical Journal Line when incorrect Lot No. validated
        WarehouseJournalLine.Validate("Lot No.", Format(LibraryRandom.RandInt(10)));
        Assert.IsTrue((WarehouseJournalLine."Expiration Date" = 0D), '');
    end;

    [Test]
    [HandlerFunctions('SetSerialItemWithQtyToHandleTrackingPageHandler,DummyMessageHandler,ConfirmHandlerYes,WarehouseItemTrackingLinesHandler')]
    procedure AvailabilityIssuesAfterUndoShipmentonAssemblytoOrderitemswithWarehouse()
    var
        ItemA: Record Item;
        ItemB: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        User: Record User;
        WarehouseEmployee: Record "Warehouse Employee";
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WhseActivityLine: Record "Warehouse Activity Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        LibraryPermissions: Codeunit "Library - Permissions";
        Quantity: Decimal;
        SerialNo: Code[20];
    begin
        // [SCENARIO 497578] Availability issues after undo Shipment on Assembly to Order items with Warehouse.
        Initialize();

        // [GIVEN] Create Item with Replenishment System: Purchase and Item Tracking Code: SNALL
        CreatePurchaseItemwithTracking(ItemA, ItemTrackingCode);

        // [GIVEN] Create Item withReplanishment System: Assembly,Assembly Policy: Assemble to order and Assmebly BOM
        CreateAssemblyItemwithBOM(ItemA, ItemB);

        // [GIVEN] Create User as administrator and Warehouse Employee
        LibraryPermissions.CreateWindowsUser(User, UserId);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);

        // [GIVEN] Assign a Quantity is 1.
        Quantity := LibraryRandom.RandIntInRange(1, 1);

        // [GIVEN] Assign a Serial No.
        SerialNo := Format(LibraryRandom.RandText(5));
        LibraryVariableStorage.Enqueue(SerialNo);

        // [GIVEN] Create Purchase order with Purchase Item.
        CreatePurchaseOrderWithItemTracking(PurchaseHeader, ItemA, Quantity, SerialNo);

        // [WHEN] Create warehouse Receipt and Put-away.
        CreateAndPostWarehouseReceiptAndPutAway(PurchaseHeader);

        // [GIVEN] Create Sales order with Assembly Item.
        CreateSalesOrderAndRelease(SalesHeader, ItemB, Quantity);

        // [WHEN] Create warehouse shipment, Pick and Register
        Clear(WhseActivityLine);
        CreateWarehouseShipmentAndPickWithRegister(SalesHeader, WarehouseShipmentHeader, WhseActivityLine, SerialNo);

        // [GIVEN] Post Warehouse Shipment.
        UpdateQtyToShipInWhseShipment(WarehouseShipmentHeader."No.", Quantity);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [WHEN] Undo sales shipment.
        FindSalesShipmentLine(SalesShipmentLine, SalesHeader."No.");
        LibrarySales.UndoSalesShipmentLine(SalesShipmentLine);

        // Exercise: Create and register Warehouse Reclassification Journal with Item Tracking.
        CreateWarehouseReclassificationJournal(WarehouseJournalLine, WhseActivityLine, LocationWhite.Code, ItemA."No.", Quantity);

        // [GIVEN] Register Warehouse Journal.
        LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalLine."Journal Template Name",
            WarehouseJournalLine."Journal Batch Name",
            LocationWhite.Code,
            true);

        //[Given] Again Create warehouse shipment, Pick and Register for Same Sales order
        Clear(WhseActivityLine);
        CreateWarehouseShipmentAndPickWithRegister(SalesHeader, WarehouseShipmentHeader, WhseActivityLine, SerialNo);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Warehouse - Journal");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        CreateDefaultWarehouseEmployeeIfNotExists();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Journal");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        CreateLocationSetup();
        NoSeriesSetup();
        SetupAssembly();

        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"Manufacturing Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Warehouse - Journal");
    end;

    local procedure InitEntryType(var EntryType: array[4] of Integer; EntryType1: Integer; EntryType2: Integer; EntryType3: Integer; EntryType4: Integer)
    begin
        EntryType[1] := EntryType1;
        EntryType[2] := EntryType2;
        EntryType[3] := EntryType3;
        EntryType[4] := EntryType4;
    end;

    local procedure MakeItemStock(var Item: Record Item; WarehouseJournalBatch: Record "Warehouse Journal Batch"; LotNo: array[2] of Code[50])
    var
        TempTrackingSpecification: Record "Tracking Specification" temporary;
    begin
        AddTwoLotsToTrackingSpecification(
          TempTrackingSpecification, LotNo, LibraryRandom.RandIntInRange(1000, 2000), LibraryRandom.RandIntInRange(1000, 2000), 0, Item."No.");
        RegisterWhseItemJournalLineWithTwoLots(WarehouseJournalBatch, TempTrackingSpecification, 1);
        LibraryWarehouse.PostWhseAdjustment(Item);
    end;

    local procedure AddTwoLotsToTrackingSpecification(var TrackingSpecification: Record "Tracking Specification"; LotNo: array[2] of Code[50]; QtyLot1: Integer; QtyLot2: Integer; EntryNo: Integer; ItemNo: Code[20])
    begin
        TrackingSpecification.Init();
        TrackingSpecification."Entry No." := EntryNo;
        TrackingSpecification."Source Ref. No." := EntryNo * 10000;
        TrackingSpecification."Item No." := ItemNo;
        TrackingSpecification."Lot No." := LotNo[1];
        TrackingSpecification."New Lot No." := LotNo[2];
        TrackingSpecification."Quantity (Base)" := QtyLot1;
        if QtyLot1 < QtyLot2 then
            QtyLot2 := QtyLot1;
        TrackingSpecification."Qty. to Handle (Base)" := QtyLot2;
        TrackingSpecification.Insert();
    end;

    local procedure CalculateAndPostWhseAdjustment(Item: Record Item)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CalculateWhseAdjustment(ItemJournalBatch, Item);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CalculateWhseAdjustment(var ItemJournalBatch: Record "Item Journal Batch"; var Item: Record Item)
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item, true);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemVariant: Code[10]; ItemNo: Code[20]; IsTracking: Boolean; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationCode, ItemVariant, ItemNo, Quantity);
        if IsTracking then
            PurchaseLine.OpenItemTrackingLines();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndPostItemJournalLineWithBin(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        CreateAndPostItemJournalLineWithBinAndTracking(ItemJournalLine, ItemNo, UnitOfMeasureCode, false);  // Item Tracking As False.
    end;

    local procedure CreateAndPostItemJournalLineWithBinAndTracking(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; ItemTracking: Boolean)
    var
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryWarehouse.CreateBin(Bin, LocationSilver.Code, LibraryUtility.GenerateGUID(), '', '');
        CreateAndUpdateBinContent(BinContent, LocationSilver.Code, Bin.Code, ItemNo, UnitOfMeasureCode);
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item, false);
        CreateItemJournalLineWithItemTracking(
          ItemJournalLine, ItemJournalBatch, Bin, ItemNo, LibraryRandom.RandDec(100, 2), ItemTracking);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndPostWarehouseReceipt(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; PurchaseHeader: Record "Purchase Header"; BinCode: Code[20]; IsTracking: Boolean)
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        if BinCode <> '' then
            UpdateBinOnWarehouseReceiptLine(WarehouseReceiptLine, BinCode);
        if IsTracking then
            WarehouseReceiptLine.OpenItemTrackingLines();
        PostWarehouseReceipt(WarehouseReceiptLine."No.");
    end;

    local procedure CreateAndRegisterWhseJournalLineWithTracking(var Item: Record Item; var LotOrSerialNos: array[5] of Code[20]; TrackingMode: Option)
    var
        ItemTrackingCode: Record "Item Tracking Code";
        Bin: Record Bin;
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        i: Integer;
    begin
        CreateItemTrackingCode(
          ItemTrackingCode, TrackingMode = ItemTrackingMode::"Serial No", TrackingMode = ItemTrackingMode::"Lot No");
        CreateItem(Item, ItemTrackingCode.Code);
        FindBin(Bin, LocationWhite.Code, true);

        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalBatch."Template Type"::Item, Bin."Location Code");
        for i := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LotOrSerialNos[i] := LibraryUtility.GenerateGUID();
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
              Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
            LibraryVariableStorage.Enqueue(TrackingMode);
            LibraryVariableStorage.Enqueue(LotOrSerialNos[i]);
            WarehouseJournalLine.OpenItemTrackingLines();
        end;
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", true);
    end;

    local procedure RegisterPutAwayFromWarehouseReceiptUsingPurchaseOrderWithItemTracking(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; IsTracking: Boolean)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, '', ItemNo, IsTracking, Quantity);
        CreateAndPostWarehouseReceipt(WarehouseReceiptLine, PurchaseHeader, '', false);  // Post Warehouse Receipt with Tracking.
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure RegisterWhseItemJournalLineWithTwoLots(WarehouseJournalBatch: Record "Warehouse Journal Batch"; TrackingSpecification: Record "Tracking Specification"; EntryType: Integer)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        Bin: Record Bin;
    begin
        FindBin(Bin, LocationWhite.Code, true);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationWhite.Code, '',
          Bin.Code, EntryType, TrackingSpecification."Item No.",
          TrackingSpecification."Quantity (Base)" + TrackingSpecification."Qty. to Handle (Base)");

        LibraryVariableStorage.Enqueue(TrackingSpecification."Lot No.");
        LibraryVariableStorage.Enqueue(Abs(TrackingSpecification."Quantity (Base)")); // value must be positive on Item Tracking Lines page
        LibraryVariableStorage.Enqueue(TrackingSpecification."New Lot No.");
        LibraryVariableStorage.Enqueue(Abs(TrackingSpecification."Qty. to Handle (Base)")); // value must be positive on Item Tracking Lines page
        WarehouseJournalLine.OpenItemTrackingLines();

        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, false);
    end;

    local procedure CreateAndUpdateWarehouseJournalLineWithBin(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalBatch: Record "Warehouse Journal Batch"; Bin: Record Bin; ItemNo: Code[20]; VariantCode: Code[10]; BaseUnitOfMeasure: Code[10])
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandInt(10));
        WarehouseJournalLine.Validate("Variant Code", VariantCode);
        WarehouseJournalLine.Validate("Unit of Measure Code", BaseUnitOfMeasure);
        WarehouseJournalLine.Modify(true);
    end;

    local procedure CreateAndPostPhysicalInventory(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Tracking: Boolean)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        RunReportCalculateInventory(ItemJournalLine, ItemNo, LocationCode, BinCode, false);
        PostPhysicalInventoryJournal(ItemJournalLine, ItemNo, Tracking);
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Qty);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
    end;

    local procedure CreateAndRegisterWhsePickFromProduction(ProductionOrder: Record "Production Order"; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivityWithLotNo(
          WarehouseActivityLine."Source Document"::"Prod. Consumption", ProductionOrder."No.",
          WarehouseActivityLine."Activity Type"::Pick, LotNo);
    end;

    local procedure CreateAndUpdateLocation(var Location: Record Location; RequireReceive: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, RequireReceive, false);
    end;

    local procedure CreateAndUpdateBinContent(var BinContent: Record "Bin Content"; LocationCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; UnitofMeasure: Code[10])
    begin
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', BinCode, ItemNo, '', UnitofMeasure);
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure CreateAndUpdateWarehouseJournalLinesWithItemTrackingAndMultipleUOM(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; ItemNo: Code[20]; ItemUnitOfMeasureCode: Code[10]; Quantity: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, ItemNo, Quantity, true);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);  // TrackingAction used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // LotNoBlank used in WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);  // AssignSerialAndLot used in WhseItemTrackingLinesHandler.
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name",
          Bin."Location Code", Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        WarehouseJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasureCode);
        WarehouseJournalLine.Modify(true);
        WarehouseJournalLine.OpenItemTrackingLines();
    end;

    local procedure CreateBlockedItem(var Item: Record Item)
    begin
        CreateItem(Item, '');
        Item.Validate(Blocked, true);
        Item.Modify(true);
    end;

    local procedure CreateBinCreationWkshTemplate(var BinCreationWkshTemplate: Record "Bin Creation Wksh. Template")
    begin
        BinCreationWkshTemplate.Init();
        BinCreationWkshTemplate.Validate(Name, LibraryUtility.GenerateGUID());
        BinCreationWkshTemplate.Validate(Type, BinCreationWkshTemplate.Type::Bin);
        BinCreationWkshTemplate.Insert(true);
    end;

    local procedure CreateBinCreationWkshName(var BinCreationWkshName: Record "Bin Creation Wksh. Name"; BinCreationWkshTemplateName: Code[10]; LocationCode: Code[10])
    begin
        BinCreationWkshName.Init();
        BinCreationWkshName.Validate("Worksheet Template Name", BinCreationWkshTemplateName);
        BinCreationWkshName.Validate(Name, LibraryUtility.GenerateGUID());
        BinCreationWkshName.Validate("Location Code", LocationCode);
        BinCreationWkshName.Insert(true);
    end;

    local procedure CreateComponentsLocationWithBin(var Location: Record Location; var Bin: Record Bin)
    begin
        CreateWMSLocationWithProductionBin(Location);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        LibraryManufacturing.SetComponentsAtLocation(Location.Code);
    end;

    local procedure CreateDimensionSet() DimSetID: Integer
    var
        GLSetup: Record "General Ledger Setup";
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        GLSetup.Get();

        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 1 Code");
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, GLSetup."Global Dimension 1 Code", DimensionValue.Code);

        LibraryDimension.CreateDimensionValue(DimensionValue, GLSetup."Global Dimension 2 Code");
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, GLSetup."Global Dimension 2 Code", DimensionValue.Code);

        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        DimSetID := LibraryDimension.CreateDimSet(DimSetID, Dimension.Code, DimensionValue.Code);
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
    end;

    local procedure CreateItem(var Item: Record Item; ItemTrackingCode: Code[10])
    begin
        LibraryInventory.CreateItem(Item);
        if ItemTrackingCode <> '' then begin
            Item.Validate("Item Tracking Code", ItemTrackingCode);
            Item.Validate("Lot Nos.", LibraryUtility.GetGlobalNoSeriesCode());
            Item.Validate("Serial Nos.", LibraryUtility.GetGlobalNoSeriesCode());
            Item.Modify(true);
        end;
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code"; Serial: Boolean; Lot: Boolean)
    begin
        LibraryItemTracking.CreateItemTrackingCodeWithExpirationDate(ItemTrackingCode, Serial, Lot);
        ItemTrackingCode.Validate("SN Warehouse Tracking", Serial);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", Lot);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateItemUnitOfMeasure(var ItemUnitOfMeasure: Record "Item Unit of Measure"; ItemNo: Code[20])
    begin
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, ItemNo, LibraryRandom.RandInt(5) + 1);
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

    local procedure CreateItemJournalLineWithItemTracking(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch"; Bin: Record Bin; ItemNo: Code[20]; Quantity: Decimal; Tracking: Boolean)
    begin
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", Bin."Location Code");
        ItemJournalLine.Validate("Bin Code", Bin.Code);
        ItemJournalLine.Modify(true);
        if Tracking then
            ItemJournalLine.OpenItemTrackingLines(false);  // Execute ItemTrackingLinesHandler for assigning Item Tracking lines.
    end;

    local procedure CreateItemReclassJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; FromLocationCode: Code[10]; ToLocationCode: Code[10]; BinCode: Code[20]; IsTracking: Boolean; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Transfer, true);
        LibraryVariableStorage.Enqueue(TrackingAction::SelectEntries);  // TrackingAction used in ItemTrackingLinesPageHandler.
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Transfer, ItemNo,
          Quantity);
        ItemJournalLine.Validate("Location Code", FromLocationCode);
        ItemJournalLine.Validate("New Location Code", ToLocationCode);
        if BinCode <> '' then
            ItemJournalLine.Validate("Bin Code", BinCode);
        ItemJournalLine.Modify(true);
        if IsTracking then
            ItemJournalLine.OpenItemTrackingLines(true);
    end;

    local procedure CreateItemWithPhysicalInventoryCountingPeriod(var Item: Record Item; var PhysInvtCountingPeriod: Record "Phys. Invt. Counting Period")
    begin
        PhysInvtCountingPeriod.FindFirst();
        LibraryInventory.CreateItem(Item);
        Item.Validate("Phys Invt Counting Period Code", PhysInvtCountingPeriod.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemWithProductionBOM(var Item: Record Item; ComponentItemNo: Code[20]; QtyPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ComponentItemNo, QtyPer);
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    local procedure CreateItemWithItemTrackingCode(var Item: Record Item; Serial: Boolean; Lot: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, Serial, Lot);
        CreateItem(Item, ItemTrackingCode.Code);
    end;

    local procedure CreateItemWithWarehouseLotTracking(var Item: Record Item)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, false, true);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
    end;

    local procedure CreateItemWithAlternateUnitOfMeasure(var ItemNo: Code[20]; var UnitOfMeasureCode: Code[10]; QtyInUOM: Decimal)
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemNo := LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", QtyInUOM);
        UnitOfMeasureCode := ItemUnitOfMeasure.Code;
    end;

    local procedure CreateLocationSetup()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.DeleteAll(true);
        CreateFullWarehouseSetup(LocationWhite);  // Location: White.
        CreateAndUpdateLocation(LocationSilver, false);  // Location: Silver.
        CreateAndUpdateLocation(LocationSilver2, true);  // Location: Silver as Require Receive as True.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(BasicLocation);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver.Code, false);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationSilver2.Code, false);
        LibraryWarehouse.CreateNumberOfBins(LocationSilver.Code, '', '', LibraryRandom.RandInt(3) + 2, false);  // Value Required.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
    end;

    local procedure CreateLocationsArray(var Location: array[3] of Record Location)
    var
        WhseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocation(Location[1]);

        LibraryWarehouse.CreateLocationWMS(Location[2], true, false, false, false, false);

        LibraryWarehouse.CreateFullWMSLocation(Location[3], 2);

        WhseEmployee.DeleteAll(true);
    end;

    local procedure CreateLocationWithEmployee(var Location: Record "Location"; var WarehouseEmployee: Record "Warehouse Employee"; IsDefault: Boolean; IsBinMandatory: Boolean; IsDirectPutAwayAndPickup: Boolean)
    begin
        LibraryWarehouse.CreateLocation(Location);
        Location.VALIDATE("Bin Mandatory", IsBinMandatory);
        Location.VALIDATE("Directed Put-away and Pick", IsDirectPutAwayAndPickup);
        Location.MODIFY(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, IsDefault);
    end;

    local procedure CreateProductionOrderWithComponent(var ProductionOrder: Record "Production Order"; ComponentItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal)
    var
        ParentItem: Record Item;
    begin
        CreateItemWithProductionBOM(ParentItem, ComponentItemNo, 1);
        CreateAndRefreshProductionOrder(ProductionOrder, ParentItem."No.", LocationCode, BinCode, Qty);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; VariantCode: Code[10]; ItemNo: Code[20]; Quantity: Integer)
    begin
        // Create Purchase Order with One Item Line. Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Variant Code", VariantCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderForPartialShipmentAndInvoice(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(100, 2));  // Use random Quantity.
        ModifyPurchaseLineForPartialShipAndInvoice(PurchaseLine, LocationCode, BinCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        LibraryVariableStorage.Enqueue(TrackingAction::SetNewLotNoWithQty);
        LibraryVariableStorage.Enqueue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(PurchaseLine."Quantity (Base)");
        LibraryVariableStorage.Enqueue(PurchaseLine."Qty. to Receive (Base)");
        LibraryVariableStorage.Enqueue(PurchaseLine."Qty. to Invoice (Base)");
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreatePurchaseOrderUpdateReceiptDate(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; VariantCode: Code[10]; ItemNo: Code[20]; Quantity: Integer; ExpectedReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseHeader, PurchaseLine, LocationCode, VariantCode, ItemNo, Quantity);
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateReservedStockOnWarehouse(var Bin: Record Bin; var Item: Record Item; Quantity: Decimal; QtyToReserve: Decimal)
    var
        Location: Record Location;
    begin
        CreateFullWarehouseSetup(Location);
        LibraryInventory.CreateItem(Item);
        Bin.Get(Location.Code, Location."Receipt Bin Code");
        PostPositiveAdjustmentOnWarehouse(Bin, Item, Quantity);
        CreateSalesOrderWithAutoReserve(Item."No.", Location.Code, QtyToReserve);
    end;

    local procedure CreateSalesOrderWithAutoReserve(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    local procedure CreateTrackedItem(var Item: Record Item)
    begin
        CreateItemWithTrackingCode(Item, false, true);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::"Tracking & Action Msg.");
        Item.Modify(true);
    end;

    local procedure CreateWarehouseJournalBatchWithItemTemplate(var WarehouseJournalBatch: Record "Warehouse Journal Batch")
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, LocationWhite.Code);
    end;

    local procedure CreateWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; WarehouseJournalTemplateType: Enum "Warehouse Journal Template Type"; ItemNo: Code[20]; Quantity: Decimal; IsTracking: Boolean)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplateType, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);
        if IsTracking then
            WarehouseJournalLine.OpenItemTrackingLines();
    end;

    local procedure CreateWhseJournalLineWithTracking(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalBatch: Record "Warehouse Journal Batch"; Bin: Record Bin; EntryType: Option "Negative Adjmt.","Positive Adjmt.",Movement; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryVariableStorage.Enqueue(0);
        // Set TrackingAction to "0" for WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(false);
        // Set LotNoBlank to "FALSE" for WhseItemTrackingLinesHandler.
        LibraryVariableStorage.Enqueue(true);  // Set AssignSerialAndLot to "TRUE" for WhseItemTrackingLinesHandler.
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, EntryType, ItemNo, Quantity);
        WarehouseJournalLine.OpenItemTrackingLines();
    end;

    local procedure CreateWhseActivityLineForPick(BinContent: Record "Bin Content")
    var
        WhseActivityLine: Record "Warehouse Activity Line";
    begin
        WhseActivityLine.Init();
        WhseActivityLine."Activity Type" := WhseActivityLine."Activity Type"::Pick;
        WhseActivityLine."No." := LibraryUtility.GenerateGUID();
        WhseActivityLine."Line No." := 1000;
        WhseActivityLine."Qty. Outstanding (Base)" := LibraryRandom.RandInt(10);
        WhseActivityLine."Location Code" := BinContent."Location Code";
        WhseActivityLine."Bin Code" := BinContent."Bin Code";
        WhseActivityLine."Item No." := BinContent."Item No.";
        WhseActivityLine."Variant Code" := BinContent."Variant Code";
        WhseActivityLine."Unit of Measure Code" := BinContent."Unit of Measure Code";
        WhseActivityLine."Action Type" := WhseActivityLine."Action Type"::Take;
        WhseActivityLine."Assemble to Order" := false;
        WhseActivityLine.Insert();
    end;

    local procedure CreateWMSLocationWithProductionBin(var Location: Record Location)
    var
        Bin: Record Bin;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, false, true, false, true);

        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');
        Location.Validate("From-Production Bin Code", Bin.Code);
        Location.Validate("To-Production Bin Code", Bin.Code);
        Location.Modify(true);

        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
    end;

    local procedure CreateBinWithContentForItem(var Bin: Record Bin; var BinContent: Record "Bin Content"): Code[20]
    var
        Item: Record Item;
    begin
        CreateItemWithTrackingCode(Item, true, true);
        FindBin(Bin, LocationWhite.Code, true);
        LibraryWarehouse.CreateBinContent(
          BinContent, Bin."Location Code", Bin."Zone Code", Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        exit(Item."No.");
    end;

    local procedure CreateWarehouseJournalAndRegister(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; WarehouseJournalTemplateType: Enum "Warehouse Journal Template Type"; ItemNo: Code[20]; Quantity: Decimal; IsTracking: Boolean)
    begin
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplateType, ItemNo, Quantity, IsTracking);

        // Register Warehouse Journal Line.
        LibraryVariableStorage.Enqueue(RegisterJournalLines); // Enqueue for ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesRegistered); // Enqueue for MessageHandler
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", false);
    end;

    local procedure CreateAndRegisterWhseJournalWithAlternateUOM(WarehouseJournalBatch: Record "Warehouse Journal Batch"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; Bin: Record Bin; Qty: Decimal; QtyBase: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Bin."Location Code",
          Bin."Zone Code", Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 0);
        WarehouseJournalLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        WarehouseJournalLine.Validate(Quantity, Qty);
        WarehouseJournalLine."Qty. (Base)" := QtyBase;
        WarehouseJournalLine."Qty. (Absolute, Base)" := Abs(WarehouseJournalLine."Qty. (Base)");
        WarehouseJournalLine.Modify(true);

        RegisterWarehouseJournalLine(WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code");
    end;

    local procedure CreateWarehouseReclassificationJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; VariantCode: Code[10]; Qty: Decimal)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type::Reclassification, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
          LocationCode, ZoneCode, BinCode, WarehouseJournalLine."Entry Type"::Movement, ItemNo, Qty);
        WarehouseJournalLine.Validate("From Zone Code", ZoneCode);
        WarehouseJournalLine.Validate("From Bin Code", BinCode);
        WarehouseJournalLine.Validate("To Zone Code", ZoneCode);
        WarehouseJournalLine.Validate("To Bin Code", BinCode);
        WarehouseJournalLine.Validate("Variant Code", VariantCode);
        WarehouseJournalLine.Modify(true);
        WarehouseJournalLine.OpenItemTrackingLines();
    end;

    local procedure CreateWarehouseReclassificationJournalAndRegister(RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; ItemVariant: Code[10])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        CreateWarehouseReclassificationJournal(
          WarehouseJournalLine, RegisteredWhseActivityLine."Location Code", RegisteredWhseActivityLine."Zone Code",
          RegisteredWhseActivityLine."Bin Code", RegisteredWhseActivityLine."Item No.", ItemVariant, RegisteredWhseActivityLine.Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          true);
    end;

    local procedure CreateWhseItemJournalFromPage(var WhseItemJournal: TestPage "Whse. Item Journal"; Bin: Record Bin; JournalBatchName: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        WhseItemJournal.OpenEdit();
        WhseItemJournal.CurrentLocationCode.SetValue(Bin."Location Code");
        WhseItemJournal.CurrentJnlBatchName.SetValue(JournalBatchName);
        WhseItemJournal."Item No.".SetValue(ItemNo);
        WhseItemJournal."Bin Code".SetValue(Bin.Code);
        WhseItemJournal.Quantity.SetValue(Quantity);
    end;

    local procedure SetupAssembly()
    var
        AssemblySetup: Record "Assembly Setup";
    begin
        AssemblySetup.Get();
        AssemblySetup.Validate("Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Posted Assembly Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        AssemblySetup.Validate("Stockout Warning", false);
        AssemblySetup.Modify(true);
    end;

    local procedure CreateFullWMSLocationWithWarehouseEmployee(var Location: Record Location)
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        CreateWarehouseEmployeeAtLocation(Location.Code);
    end;

    local procedure CreateRequirePutawayLocationWithWarehouseEmployee(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, false, false, false);
        CreateWarehouseEmployeeAtLocation(Location.Code);
    end;

    local procedure CreateWarehouseEmployeeAtLocation(LocationCode: Code[10])
    var
        WarehouseEmployeeLoc: Record "Warehouse Employee";
    begin
        WarehouseEmployeeLoc.SetRange("User ID", UserId);
        WarehouseEmployeeLoc.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployeeLoc, LocationCode, true);
    end;

    local procedure CreateWMSLocationWithTwoBins(var Location: Record Location)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, true, true, true, true, true);
        LibraryWarehouse.CreateNumberOfBins(Location.Code, '', '', 2, false);
    end;

    local procedure CreateLocationBinMandatory(var Location: Record Location)
    var
        Bin: Record Bin;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
        Location.Validate("Default Bin Code", Bin.Code);
        Location.Modify(true);
    end;

    local procedure CreateLocationWithBins(var Location: Record Location; BinCount: Integer) BinCodeList: List of [Code[20]]
    var
        Bin: Record Bin;
        i: Integer;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        if BinCount <= 0 then
            exit;

        Location.Validate("Bin Mandatory", true);

        for i := 1 to BinCount do begin
            Clear(Bin);
            LibraryWarehouse.CreateBin(Bin, Location.Code, '', '', '');
            BinCodeList.Add(Bin.Code);

            if i = 1 then begin
                Location.Validate("Default Bin Code", Bin.Code);
                Location.Modify(true);
            end;
        end;
    end;

    local procedure AddVariantsToItem(Item: Record Item; VariantCode: Code[10])
    var
        ItemVariant: Record "Item Variant";
    begin
        Clear(ItemVariant);
        ItemVariant.Init();
        ItemVariant.Validate("Item No.", Item."No.");
        ItemVariant.Validate(Code, VariantCode);
        ItemVariant.Insert(true);
    end;

    local procedure SetDefaultBinContent(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.Init();
        BinContent.Validate("Location Code", LocationCode);
        BinContent.Validate("Bin Code", BinCode);
        BinContent.Validate("Item No.", ItemNo);
        BinContent.Validate("Variant Code", VariantCode);
        BinContent.Validate(Default, true);
        if not BinContent.Insert() then
            BinContent.Modify();
    end;

    local procedure CreateLocationsChain(var FromLocation: Record Location; var ToLocation: Record Location; var TransitLocation: Record Location)
    var
        TransferRoute: Record "Transfer Route";
    begin
        CreateLocationBinMandatory(FromLocation);
        CreateLocationBinMandatory(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(TransitLocation);
        LibraryInventory.CreateTransferRoute(TransferRoute, FromLocation.Code, ToLocation.Code);
        TransferRoute.Validate("In-Transit Code", TransitLocation.Code);
        TransferRoute.Modify(true);
    end;

    local procedure CreateWarehouseJournalLineWithInBatch(var Item: Record Item; var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalBatch: Record "Warehouse Journal Batch"; Location: Record Location; Quantity: Decimal)
    var
        Bin: Record Bin;
    begin
        Bin.Get(Location.Code, Location."Cross-Dock Bin Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code",
          Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Quantity);
    end;

    local procedure CreateAssemblyOrderWithInventory(var AssemblyHeader: Record "Assembly Header"; var Item: Record Item; LocationCode: Code[10]; HeaderBinCode: Code[20]; ComponentsBinCode: Code[20])
    begin
        CreateAssembledItem(Item);
        CreateAssemblyOrder(AssemblyHeader, Item, LocationCode, HeaderBinCode);

        // Add enough inventory for comp and post
        LibraryAssembly.AddCompInventoryToBin(AssemblyHeader, WorkDate(), 0, LocationCode, ComponentsBinCode);
    end;

    local procedure CreateAssembledItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Validate("Assembly Policy", Item."Assembly Policy"::"Assemble-to-Stock");
        Item.Modify(true);
        CreateAssemblyList(Item);
    end;

    local procedure CreateAssemblyOrder(var AssemblyHeader: Record "Assembly Header"; ParentItem: Record Item; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), ParentItem."No.", LocationCode, 1, '');
        AssemblyHeader.Validate("Bin Code", BinCode);
        AssemblyHeader.Modify(true);
    end;

    local procedure CreateAssemblyList(ParentItem: Record Item)
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        i: Integer;
    begin
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item);
            LibraryInventory.CreateBOMComponent(
              BOMComponent, ParentItem."No.", BOMComponent.Type::Item, Item."No.", 1, ParentItem."Base Unit of Measure");
        end;
    end;

    local procedure CreateDefaultWarehouseEmployeeIfNotExists()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        if LocationWhite.Code = '' then
            exit;

        if WarehouseEmployee.Get(UserId, LocationWhite.Code) then
            exit;

        WarehouseEmployee.SetRange(Default, true);
        WarehouseEmployee.DeleteAll();
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, LocationWhite.Code, true);
    end;

    local procedure CreateRoutingAndUpdateItem(var Item: Record Item; var WorkCenter: Record "Work Center"): Code[10]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingLink: Record "Routing Link";
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, WorkCenter."No.",
          LibraryUtility.GenerateRandomCode(RoutingLine.FieldNo("Operation No."), DATABASE::"Routing Line"),
          LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));

        LibraryManufacturing.CreateRoutingLink(RoutingLink);
        RoutingLine.Validate("Routing Link Code", RoutingLink.Code);
        RoutingLine.Modify(true);

        // Certify Routing after Routing lines creation.
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        // Update Routing No on Item.
        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Modify(true);

        exit(RoutingLink.Code);
    end;

    local procedure CreateProductionItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateItemWithBOMAndRouting(var Item: Record Item; var ChildItem: Record Item; QuantityPer: Decimal)
    var
        WorkCenter: Record "Work Center";
    begin
        CreateItemsSetup(Item, ChildItem, QuantityPer);
        UpdateFlushingMethodOnItem(ChildItem, ChildItem."Flushing Method"::"Pick + Backward");
        UpdateBOMHeader(Item."Production BOM No.", ChildItem."No.", CreateRoutingAndUpdateItem(Item, WorkCenter));
    end;

    local procedure CreateItemWithTrackingCode(var Item: Record Item; SerialNoTracking: Boolean; LotNoTracking: Boolean)
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        CreateItemTrackingCode(ItemTrackingCode, SerialNoTracking, LotNoTracking);
        CreateItem(Item, ItemTrackingCode.Code);
    end;

    local procedure CreateItemsSetup(var Item: Record Item; var ChildItem: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Child Item.
        LibraryInventory.CreateItem(ChildItem);

        // Create Production BOM, Parent Item and attach Production BOM.
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", QuantityPer);
        CreateProductionItem(Item, ProductionBOMHeader."No.");
    end;

    local procedure CreatePick(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; WarehouseShipmentNo: Code[20])
    begin
        WarehouseShipmentHeader.Get(WarehouseShipmentNo);
        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
    end;

    local procedure WhseShipFromSOWithNewBinCode(SalesHeader: Record "Sales Header"; WarehouseShipmentNo: Code[20]; NewBinCode: Code[20])
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        ChangeBinCodeOnWhseShipLine(NewBinCode, WarehouseShipmentNo);
    end;

    local procedure ChangeBinCodeOnWhseShipLine(NewBinCode: Code[20]; WarehouseShipmentNo: Code[20])
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        FilterWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentNo);
        WarehouseShipmentLine.ModifyAll("Bin Code", NewBinCode, true);
    end;

    local procedure CreateItemInventory(var Item: Record Item; Location: Record Location; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryInventory.CreateItem(Item);
        CreatePurchaseOrderDefaultBin(PurchaseHeader, Location, Item."No.", Quantity);
        PostPurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateItemAddInventory(var Item: Record Item; LocationCode: Code[10]; BinCode: Code[20])
    begin
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(Item."No.", LocationCode, BinCode, 1);
    end;

    local procedure CreateItemWithReplenishmentSystemAndManufacturingPolicy(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ManufacturingPolicy: Enum "Manufacturing Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Manufacturing Policy", ManufacturingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Bin Code", BinCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreatePurchaseOrderTwoLinesWithWhseReceipt(var WhseReceiptLine: Record "Warehouse Receipt Line")
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        i: Integer;
    begin
        CreateFullWMSLocationWithWarehouseEmployee(Location);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        for i := 1 to 2 do begin
            LibraryInventory.CreateItem(Item);
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        end;

        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WhseReceiptLine.SetRange("Source Document", WhseReceiptLine."Source Document"::"Purchase Order");
        WhseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WhseReceiptLine.FindFirst();
    end;

    local procedure CreatePurchaseOrderTwoLinesWithPutaway(var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        WarehouseActivityHeader: Record "Warehouse Activity Header";
    begin
        CreateRequirePutawayLocationWithWarehouseEmployee(Location);
        CreatePurchaseOrderTwoLinesAtLocation(PurchaseHeader, Location.Code);

        LibraryWarehouse.CreateInvtPutPickMovement(
          WarehouseActivityHeader."Source Document"::"Purchase Order", PurchaseHeader."No.", true, false, false);

        WarehouseActivityHeader.SetRange("Location Code", Location.Code);
        WarehouseActivityHeader.FindFirst();
        LibraryWarehouse.AutoFillQtyInventoryActivity(WarehouseActivityHeader);

        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type);
        WarehouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WarehouseActivityLine.FindFirst();
    end;

    local procedure CreatePurchaseOrderDefaultBin(var PurchaseHeader: Record "Purchase Header"; Location: Record Location; ItemNo: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Location Code", Location.Code);
        PurchaseLine.Validate("Bin Code", Location."Default Bin Code");
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderTwoLines(var PurchaseHeader: Record "Purchase Header")
    var
        Location: Record Location;
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        CreateLocationBinMandatory(Location);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Location Code", Location.Code);
        PurchaseHeader.Modify(true);
        for i := 1 to 2 do
            CreatePurchaseLineAtBin(PurchaseLine, PurchaseHeader, Location."Default Bin Code", LibraryInventory.CreateItemNo(), 1);
    end;

    local procedure CreatePurchaseOrderTwoLinesAtLocation(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10])
    var
        Location: Record Location;
        Item: Record Item;
        Bin: Record Bin;
        BinContent: Record "Bin Content";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Location Code", LocationCode);
        PurchaseHeader.Modify(true);
        for i := 1 to 2 do begin
            LibraryWarehouse.CreateBin(
              Bin, LocationCode,
              CopyStr(
                LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
                LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');

            CreateItem(Item, '');
            CreateFixedDefaultBinContent(BinContent, Item, Bin);
            CreatePurchaseLineAtBin(PurchaseLine, PurchaseHeader, Location."Default Bin Code", Item."No.", 1);
        end;
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateFixedDefaultBinContent(var BinContent: Record "Bin Content"; Item: Record Item; Bin: Record Bin)
    begin
        LibraryWarehouse.CreateBinContent(BinContent, Bin."Location Code", '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Fixed, false);
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure CreatePurchaseLineAtBin(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; BinCode: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrderTwoLines(var SalesHeader: Record "Sales Header")
    var
        Location: Record Location;
        Item: Record Item;
        SalesLine: Record "Sales Line";
        i: Integer;
    begin
        CreateLocationBinMandatory(Location);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        for i := 1 to 2 do begin
            CreateItemInventory(Item, Location, 1);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
            SalesLine.Validate("Bin Code", Location."Default Bin Code");
            SalesLine.Modify(true);
        end;
    end;

    local procedure CreateTransferOrderTwoLines(var TransferHeader: Record "Transfer Header")
    var
        FromLocation: Record Location;
        ToLocation: Record Location;
        TransitLocation: Record Location;
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        i: Integer;
    begin
        CreateLocationsChain(FromLocation, ToLocation, TransitLocation);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, TransitLocation.Code);
        for i := 1 to 2 do begin
            CreateItemInventory(Item, FromLocation, 1);
            LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
            TransferLine.Validate("Transfer-from Bin Code", FromLocation."Default Bin Code");
            TransferLine.Validate("Transfer-To Bin Code", ToLocation."Default Bin Code");
            TransferLine.Modify(true);
        end;
    end;

    local procedure CreateServiceOrderTwoItemLines(var ServiceHeader: Record "Service Header")
    var
        Location: Record Location;
        Item: Record Item;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        CustomerNo: Code[20];
        i: Integer;
    begin
        CreateLocationBinMandatory(Location);
        CustomerNo := LibrarySales.CreateCustomerNo();
        LibraryService.CreateServiceItem(ServiceItem, CustomerNo);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, CustomerNo);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        ServiceHeader.Validate("Location Code", Location.Code);
        ServiceHeader.Modify(true);
        for i := 1 to 2 do begin
            CreateItemInventory(Item, Location, 1);
            LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, Item."No.");
            ServiceLine.Validate("Service Item No.", ServiceItem."No.");
            ServiceLine.Validate("Bin Code", Location."Default Bin Code");
            ServiceLine.Validate("Quantity (Base)", 1);
            ServiceLine.Modify(true);
        end;
    end;

    local procedure CreateJobJournalTwoItemLines(var JobJournalLine: Record "Job Journal Line")
    var
        Location: Record Location;
        Item: Record Item;
        Job: Record Job;
        JobTask: Record "Job Task";
        i: Integer;
    begin
        CreateLocationBinMandatory(Location);
        Location.Modify(true);
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        for i := 1 to 2 do begin
            CreateItemInventory(Item, Location, 1);
            LibraryJob.CreateJobJournalLine(JobJournalLine."Line Type"::Budget, JobTask, JobJournalLine);
            JobJournalLine.Validate(Type, JobJournalLine.Type::Item);
            JobJournalLine.Validate("No.", Item."No.");
            JobJournalLine.Validate("Location Code", Location.Code);
            JobJournalLine.Validate("Bin Code", Location."Default Bin Code");
            JobJournalLine.Validate("Quantity (Base)", 1);
            JobJournalLine.Modify(true);
        end;
    end;

    local procedure CreateItemJournalTwoLines(var ItemJournalBatch: Record "Item Journal Batch")
    var
        Location: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalLine: Record "Item Journal Line";
        i: Integer;
    begin
        CreateLocationBinMandatory(Location);
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        for i := 1 to 2 do begin
            LibraryInventory.CreateItemJournalLine(
              ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
              ItemJournalLine."Entry Type"::Purchase, LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(10, 20));
            ItemJournalLine.Validate("Source Type", ItemJournalLine."Source Type"::Vendor);
            ItemJournalLine.Validate("Source No.", LibraryPurchase.CreateVendorNo());
            ItemJournalLine.Validate("Location Code", Location.Code);
            ItemJournalLine.Validate("Bin Code", Location."Default Bin Code");
            ItemJournalLine.Modify(true);
        end;
    end;

    local procedure CreateOutputJournalTwoLines()
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        i: Integer;
    begin
        CreateLocationBinMandatory(Location);
        CreateItemWithReplenishmentSystemAndManufacturingPolicy(
          Item, "Replenishment System"::"Prod. Order", "Manufacturing Policy"::"Make-to-Order");
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released,
          ProductionOrder."Source Type"::Item, Item."No.", 2);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Output, ItemJournalTemplate.Name);
        for i := 1 to 2 do begin
            LibraryManufacturing.CreateOutputJournal(
              ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, Item."No.", ProductionOrder."No.");
            ItemJournalLine.Validate("Location Code", Location.Code);
            ItemJournalLine.Validate("Bin Code", Location."Default Bin Code");
            ItemJournalLine.Validate("Output Quantity", 1);
            ItemJournalLine.Modify(true);
        end;
    end;

    local procedure CreateConsumptionJournalTwoLines(var ConsumptionItemJournalBatch: Record "Item Journal Batch")
    var
        Location: Record Location;
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ConsumptionItemJournalTemplate: Record "Item Journal Template";
        ItemTrackingCodeSerialSpecificWithWarehouse: Record "Item Tracking Code";
        Item: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ItemJournalLine: Record "Item Journal Line";
        Bin: Record Bin;
        ProductionBOMHeader: Record "Production BOM Header";
        Quantity: Decimal;
    begin
        CreateLocationBinMandatory(Location);

        CreateSerialSpecificWithWarehouseItemTrackingCode(ItemTrackingCodeSerialSpecificWithWarehouse);
        CreateItem(Item, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateItem(ChildItem, ItemTrackingCodeSerialSpecificWithWarehouse.Code);
        CreateBinAndBinContent(Bin, Item, Location.Code);
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item, LibraryERM.CreateNoSeriesCode());
        ItemJournalSetup(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch, ConsumptionItemJournalTemplate.Type::Consumption, '');

        Quantity := 2;

        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."Base Unit of Measure", Item."No.");
        UpdateProductionBOMNoOnItem(ChildItem, ProductionBOMHeader."No.");

        LibraryVariableStorage.Enqueue(AssignTracking::SerialNo); // Enqueue for ItemTrackLinesPageHandler
        CreateAndPostItemJournalLineWithTracking(ItemJournalTemplate, ItemJournalBatch,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", Location.Code, Quantity);

        CreateAndRefreshReleasedProductionOrder(ProductionOrder, ChildItem."No.", Location.Code, Bin.Code, Quantity);

        LibraryVariableStorage.Enqueue(AssignTracking::SelectTrackingEntries); // Enqueue for ItemTrackLinesPageHandler
        CreateConsumptionJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch, ProductionOrder."No.");
    end;

    local procedure CreateProductionOrderFlushingConsumptionOneLine(var ProductionOrder: Record "Production Order"): Integer
    var
        Location: Record Location;
        Item: Record Item;
        ChildItem: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateFullWMSLocationWithWarehouseEmployee(Location);

        CreateItemWithBOMAndRouting(Item, ChildItem, 1);
        UpdateInventoryWithWhseItemJournal(ChildItem, Location, 1);
        CreateAndRefreshReleasedProductionOrder(
          ProductionOrder, Item."No.",
          Location.Code, Location."To-Production Bin Code", 1);
        // Create and register Pick from Released Production Order.
        LibraryManufacturing.CreateWhsePickFromProduction(ProductionOrder);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Prod. Consumption",
          ProductionOrder."No.", WarehouseActivityLine."Activity Type"::Pick);
        FindReleasedProdOrderLine(ProdOrderLine, Item."No.");
        exit(ProdOrderLine."Line No.");
    end;

    local procedure CreateTwoItemLedgerEntriesAtLocation(var Location: Record Location)
    var
        Item: Record Item;
        i: Integer;
    begin
        for i := 1 to 2 do
            CreateItemInventory(Item, Location, 1);
    end;

    local procedure CreatePickedAssemblyOrderWithTwoComponents(var AssemblyHeader: Record "Assembly Header")
    var
        Location: Record Location;
        Item: Record Item;
        HeaderBin: Record Bin;
        ComponentsBin: Record Bin;
    begin
        CreateFullWMSLocationWithWarehouseEmployee(Location);

        HeaderBin.Get(Location.Code, Location."From-Assembly Bin Code");
        CreateBinWithZone(ComponentsBin, Location.Code);
        CreateAssemblyOrderWithInventory(AssemblyHeader, Item, Location.Code, HeaderBin.Code, ComponentsBin.Code);
        LibraryAssembly.ReleaseAO(AssemblyHeader);

        AssemblyHeader.Validate("Quantity to Assemble", 1);
        AssemblyHeader.Modify(true);
        LibraryAssembly.CreateWhsePick(AssemblyHeader, UserId, 0, false, true, false);
        RegisterPickWithQtyToHandle(AssemblyHeader, 1);
    end;

    local procedure CreateBinWithZone(var Bin: Record Bin; LocationCode: Code[10])
    var
        BinType: Record "Bin Type";
        Zone: Record Zone;
    begin
        BinType.Get(LibraryWarehouse.SelectBinType(false, false, false, true));
        LibraryWarehouse.CreateZone(Zone, '', LocationCode, BinType.Code, '', '', 1, false);
        LibraryWarehouse.CreateBin(Bin, LocationCode, '', Zone.Code, BinType.Code);
    end;

    local procedure CreateWarehouseJournalBatchWithTwoLines(var WarehouseJournalLine: Record "Warehouse Journal Line")
    var
        Location: Record Location;
        Item: Record Item;
        Bin: Record Bin;
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        i: Integer;
    begin
        CreateFullWMSLocationWithWarehouseEmployee(Location);
        CreateBinWithZone(Bin, Location.Code);

        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        WarehouseJournalBatch.Validate("No. Series", '');
        WarehouseJournalBatch.Modify(true);
        for i := 1 to 2 do begin
            CreateItem(Item, '');
            LibraryWarehouse.CreateWhseJournalLine(
              WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, Bin."Zone Code",
              Bin.Code, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", Item."No.", 1);
        end;
    end;

    local procedure CreateSalesOrderTwoLinesWithWhseShipmentAndPick(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Bin: array[2] of Record Bin;
        WarehouseShipmentNo: Code[20];
        i: Integer;
    begin
        CreateWMSLocationWithTwoBins(Location);

        LibraryWarehouse.FindBin(Bin[1], Location.Code, '', 1);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Location Code", Location.Code);
        SalesHeader.Modify(true);
        for i := 1 to 2 do begin
            CreateItemAddInventory(Item, Location.Code, Bin[1].Code);
            LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", 1);
        end;

        LibrarySales.ReleaseSalesDocument(SalesHeader);
        WarehouseShipmentNo := FindWarehouseShipmentNo();
        LibraryWarehouse.FindBin(Bin[2], Location.Code, '', 2);
        WhseShipFromSOWithNewBinCode(SalesHeader, WarehouseShipmentNo, Bin[2].Code);
        CreatePick(WarehouseShipmentHeader, WarehouseShipmentNo);

        WarehouseShipmentLine.SetRange("No.", WarehouseShipmentHeader."No.");
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure CreateBinAndBinContent(var Bin: Record Bin; Item: Record Item; LocationCode: Code[10])
    var
        BinContent: Record "Bin Content";
    begin
        LibraryWarehouse.CreateBin(
          Bin, LocationCode,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), 1,
            LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
        LibraryWarehouse.CreateBinContent(BinContent, LocationCode, '', Bin.Code, Item."No.", '', Item."Base Unit of Measure");
        BinContent.Validate(Default, true);
        BinContent.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; ItemNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, 1);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLineWithTracking(ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJnlLine(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, EntryType, ItemNo, LocationCode, Quantity, 0);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateConsumptionJournal(var ConsumptionItemJournalTemplate: Record "Item Journal Template"; var ConsumptionItemJournalBatch: Record "Item Journal Batch"; ProductionOrderNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.ClearItemJournal(ConsumptionItemJournalTemplate, ConsumptionItemJournalBatch);
        Commit();
        LibraryManufacturing.CalculateConsumption(
          ProductionOrderNo, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        UpdateItemJnlLineDocNo(ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        SelectItemJournalLine(ItemJournalLine, ConsumptionItemJournalTemplate.Name, ConsumptionItemJournalBatch.Name);
        ItemJournalLine.OpenItemTrackingLines(false);  // Assign Tracking Line on Page Handler.
    end;

    local procedure CreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalTemplate: Record "Item Journal Template"; ItemJournalBatch: Record "Item Journal Batch"; EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; Amount: Decimal)
    begin
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Validate(Amount, Amount);
        ItemJournalLine.Modify(true);
    end;

    local procedure CalculateWhseAdjustmentAndPostCreatedItemJournalLine(Item: Record Item; ItemJournalBatch: Record "Item Journal Batch")
    begin
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure ItemJournalSetup(var ItemJournalTemplate: Record "Item Journal Template"; var ItemJournalBatch: Record "Item Journal Batch"; Type: Enum "Item Journal Template Type"; NoSeriesCode: Code[20])
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        ItemJournalTemplate.Type := Type;
        ItemJournalTemplate.Modify();
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch."Template Type" := Type;
        ItemJournalBatch."No. Series" := NoSeriesCode;
        ItemJournalBatch.Modify();
    end;

    local procedure CreateSerialSpecificWithWarehouseItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
    end;

    local procedure PostPurchaseDocument(PurchaseHeader: Record "Purchase Header")
    begin
        // Update Vendor Invoice No on Purchase Header.
        PurchaseHeader.Validate("Vendor Invoice No.", PurchaseHeader."No.");
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure AdjustInventoryToZeroAfterAddInventoryForItem(var Bin: Record Bin): Code[20]
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Add Inventory for Item.
        Initialize();
        CreateItem(Item, '');
        RegisterPutAwayFromWarehouseReceiptUsingPurchaseOrderWithItemTracking(
          PurchaseHeader, Item."No.", LibraryRandom.RandInt(10), false);

        // Adjust Inventory to 0.
        RunWarehouseCalculateInventory(WarehouseJournalLine, '', LocationWhite.Code, Item."No.");
        UpdatePhysicalInventoryAndRegister(WarehouseJournalLine, Item."No.");
        CalculateAndPostWhseAdjustment(Item);

        Bin.Get(LocationWhite.Code, LocationWhite."Receipt Bin Code");
        exit(Item."No.");
    end;

    local procedure DeleteBin(LocationCode: Code[20]; BinCode: Code[20])
    var
        Bin: Record Bin;
    begin
        Bin.SetRange(Code, BinCode);
        Bin.SetRange("Location Code", LocationCode);
        Bin.FindFirst();
        Bin.Delete(true);
    end;

    local procedure DeleteBinContent(LocationCode: Code[20]; BinCode: Code[20]; ItemNo: Code[20]; LotNo: Code[50])
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Bin Code", BinCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Lot No. Filter", LotNo);
        BinContent.FindFirst();
        BinContent.Delete(true);
    end;

    local procedure FilterItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; ItemNo: Code[20])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.SetRange("Item No.", ItemNo);
    end;

    local procedure FIlterWarehouseEntries(var WarehouseEntry: Record "Warehouse Entry"; EntryType: Option; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Location Code", LocationCode);
    end;

    local procedure FilterWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LocationCode: Code[10])
    begin
        WarehouseJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        WarehouseJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        WarehouseJournalLine.SetRange("Location Code", LocationCode);
    end;

    local procedure FilterPurchRcptLineByOrderNo(var PurchRcptLine: Record "Purch. Rcpt. Line"; OrderNo: Code[20])
    begin
        PurchRcptLine.SetRange("Order No.", OrderNo);
        PurchRcptLine.SetRange(Type, PurchRcptLine.Type::Item);
    end;

    local procedure FilterSalesShipmentLineByOrderNo(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
    end;

    local procedure FilterServiceShipmentLineByOrderNo(var ServiceShipmentLine: Record "Service Shipment Line"; OrderNo: Code[20])
    begin
        ServiceShipmentLine.SetRange("Order No.", OrderNo);
        ServiceShipmentLine.SetRange(Type, ServiceShipmentLine.Type::Item);
    end;

    local procedure FilterWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; No: Code[20])
    begin
        WarehouseShipmentLine.SetRange("No.", No);
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10]; Pick: Boolean)
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, Pick));
        LibraryWarehouse.FindBin(Bin, LocationCode, Zone.Code, 1);  // Use 1 for Bin Index.
    end;

    local procedure FindDimensionSetEntry(DimSetID: Integer; DimValueCode: Code[20]): Code[20]
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Set ID", DimSetID);
        DimensionSetEntry.SetRange("Dimension Code", DimValueCode);
        DimensionSetEntry.FindFirst();
        exit(DimensionSetEntry."Dimension Value Code");
    end;

    local procedure FindRegisteredPutAway(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; ItemNo: Code[20])
    begin
        RegisteredWhseActivityLine.SetRange("Action Type", RegisteredWhseActivityLine."Action Type"::Place);
        RegisteredWhseActivityLine.SetRange("Item No.", ItemNo);
        RegisteredWhseActivityLine.FindFirst();
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10]; ItemNo: Code[20])
    begin
        FilterItemJournalLine(ItemJournalLine, JournalTemplateName, JournalBatchName, ItemNo);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; EntryType: Enum "Item Ledger Entry Type"; LocationCode: Code[10]; ItemNo: Code[20]): Boolean
    begin
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        exit(ItemLedgerEntry.FindFirst())
    end;

    local procedure FindWarehouseActivityNo(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemNo: Code[20])
    begin
        WarehouseJournalLine.SetRange("Journal Template Name", WarehouseJournalLine."Journal Template Name");
        WarehouseJournalLine.SetRange("Journal Batch Name", WarehouseJournalLine."Journal Batch Name");
        WarehouseJournalLine.SetRange("Location Code", WarehouseJournalLine."Location Code");
        WarehouseJournalLine.SetRange("Item No.", ItemNo);
        WarehouseJournalLine.FindFirst();
    end;

    local procedure FindZone(var Zone: Record Zone; LocationCode: Code[10]; BinTypeCode: Code[10])
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", BinTypeCode);
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
    end;

    local procedure FindWarehouseJournalBatch(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; JournalTemplateName: Code[10]; NoSeries: Code[20])
    begin
        WarehouseJournalBatch.SetRange("Journal Template Name", JournalTemplateName);
        WarehouseJournalBatch.SetRange("No. Series", NoSeries);
        WarehouseJournalBatch.FindLast();
    end;

    local procedure FindWarehouseEntry(var WarehouseEntry: Record "Warehouse Entry"; JournalBatchName: Code[10]; EntryType: Option; ItemNo: Code[20])
    begin
        WarehouseEntry.SetRange("Journal Batch Name", JournalBatchName);
        WarehouseEntry.SetRange("Entry Type", EntryType);
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.FindFirst();
    end;

    local procedure FindReleasedProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindProdBOMLine(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeaderNo);
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ItemNo);
        ProductionBOMLine.FindFirst();
    end;

    local procedure FindLastWarehouseRegisterNo() LastWarehouseRegisterNo: Integer
    var
        WarehouseRegister: Record "Warehouse Register";
    begin
        LastWarehouseRegisterNo := 0;
        if WarehouseRegister.FindLast() then
            LastWarehouseRegisterNo := WarehouseRegister."No.";
    end;

    local procedure FindWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; AssemblyHeader: Record "Assembly Header")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityHeader.Type::Pick);
        WarehouseActivityLine.SetRange("Source No.", AssemblyHeader."No.");
        WarehouseActivityLine.SetRange("Source Document", WarehouseRequest."Source Document"::"Assembly Consumption");
        WarehouseActivityLine.SetRange("Source Type", DATABASE::"Assembly Line");
        WarehouseActivityLine.SetRange("Source Subtype", AssemblyHeader."Document Type");
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentNo(): Code[20]
    var
        WarehouseSetup: Record "Warehouse Setup";
        NoSeries: Codeunit "No. Series";
    begin
        WarehouseSetup.Get();
        exit(NoSeries.PeekNextNo(WarehouseSetup."Whse. Ship Nos."));
    end;

    local procedure InvokeOpenWarehouseJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseJournalTemplateName: Code[10]; WarehouseJournalBatchName: Code[10]; WarehouseLocationCode: Code[10])
    begin
        WarehouseJournalLine.Init();
        WarehouseJournalLine.SETRANGE("Journal Template Name", WarehouseJournalTemplateName);
        WarehouseJournalLine.SETRANGE("Journal Batch Name", WarehouseJournalBatchName);
        WarehouseJournalLine.SETRANGE("Location Code", WarehouseLocationCode);
        WarehouseJournalLine.OpenJnl(WarehouseJournalBatchName, WarehouseLocationCode, WarehouseJournalLine);
        WarehouseJournalLine.FILTERGROUP := 2;
    end;

    local procedure MockBinContent(Bin: Record Bin)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent."Location Code" := Bin."Location Code";
        BinContent."Zone Code" := Bin."Zone Code";
        BinContent."Bin Code" := Bin.Code;
        if BinContent.Insert() then;
    end;

    local procedure MockWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; EntryType: Option)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.SelectWhseJournalBatchName(
          WarehouseJournalBatch, WarehouseJournalTemplate.Type, WarehouseJournalTemplate.Name, LocationCode);
        WarehouseJournalLine."Journal Template Name" := WarehouseJournalTemplate.Name;
        WarehouseJournalLine."Journal Batch Name" := WarehouseJournalBatch.Name;
        WarehouseJournalLine."Location Code" := LocationCode;
        WarehouseJournalLine."Entry Type" := EntryType;
        WarehouseJournalLine.Insert();
    end;

    local procedure ModifyPurchaseLineForPartialShipAndInvoice(var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10]; BinCode: Code[20])
    begin
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Validate("Qty. to Receive", PurchaseLine.Quantity / 2);  // Assign Partial Quantity to Receive.
        PurchaseLine.Validate("Qty. to Invoice", PurchaseLine.Quantity / 4);  // Assign Partial Quantity to Invoice.
        PurchaseLine.Modify(true);
    end;

    local procedure ModifyWhseJournalLineForReclass(WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; Bin2: Record Bin)
    begin
        WarehouseJournalLine.Validate("From Zone Code", Bin."Zone Code");
        WarehouseJournalLine.Validate("From Bin Code", Bin.Code);
        WarehouseJournalLine.Validate("To Zone Code", Bin2."Zone Code");
        WarehouseJournalLine.Validate("To Bin Code", Bin2.Code);
        WarehouseJournalLine.Modify(true);
    end;

    local procedure NoSeriesSetup()
    var
        WarehouseSetup: Record "Warehouse Setup";
    begin
        LibraryPurchase.SetOrderNoSeriesInSetup();
        LibraryWarehouse.NoSeriesSetup(WarehouseSetup);
    end;

    local procedure CalculateInventoryOnPhysicalInventoryJournalPage(var PhysInventoryJournal: TestPage "Phys. Inventory Journal"; ItemNo: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ItemNo);  // ItemNo used in CalculateInventoryPageHandler.
        PhysInventoryJournal.OpenEdit();
        PhysInventoryJournal.CalculateInventory.Invoke();
        PhysInventoryJournal.FILTER.SetFilter("Item No.", ItemNo);
    end;

    local procedure PostItemPositiveAdjmtWithLotTracking(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Qty: Decimal): Code[50]
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Qty);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignLotNo);
        ItemJournalLine.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.FindLast();

        exit(ItemLedgerEntry."Lot No.");
    end;

    local procedure PostPhysicalInventoryJournal(ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; Tracking: Boolean)
    var
        ItemJournalLine2: Record "Item Journal Line";
    begin
        ItemJournalLine2.SetRange("Journal Template Name", ItemJournalLine."Journal Template Name");
        ItemJournalLine2.SetRange("Journal Batch Name", ItemJournalLine."Journal Batch Name");
        ItemJournalLine2.SetRange("Item No.", ItemNo);
        ItemJournalLine2.FindFirst();
        ItemJournalLine2.Validate("Qty. (Phys. Inventory)", 0); // Value Zero Important for test.
        ItemJournalLine2.Modify(true);
        if Tracking then
            ItemJournalLine2.OpenItemTrackingLines(false);
        LibraryInventory.PostItemJournalLine(ItemJournalLine2."Journal Template Name", ItemJournalLine2."Journal Batch Name");
    end;

    local procedure PostPositiveAdjustmentOnWarehouse(Bin: Record Bin; Item: Record Item; Quantity: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalLine: Record "Warehouse Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateWarehouseJournalLine(
          WarehouseJournalLine, Bin, WarehouseJournalTemplate.Type::Item, Item."No.", Quantity, false);
        LibraryVariableStorage.Enqueue(RegisterJournalLines);
        LibraryVariableStorage.Enqueue(JournalLinesRegistered);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", Bin."Location Code", false);
        CalculateWhseAdjustment(ItemJournalBatch, Item);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure PostWarehouseReceipt(WarehouseReceiptNo: Code[20])
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
    begin
        WarehouseReceiptHeader.Get(WarehouseReceiptNo);
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure PostWarehouseReceiptAndRegisterPutAway(LocationCode: Code[10]; ItemVariant: Code[10]; ItemNo: Code[20]; BinCode: Code[20]; Quantity: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationCode, ItemVariant, ItemNo, true, Quantity);
        CreateAndPostWarehouseReceipt(WarehouseReceiptLine, PurchaseHeader, BinCode, false);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure PostWarehouseReceiptAndRegisterPutAwayForSerialNo(var RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; ItemVariant: Code[10]; Quantity: Decimal; UpdateExpirationDate: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CreateItemWithTrackingCode(Item, true, false);
        LibraryVariableStorage.Enqueue(TrackingAction::AssignSerialNo);  // TrackingAction used in ItemTrackingLinesPageHandler.
        CreateAndReleasePurchaseOrder(PurchaseHeader, LocationWhite.Code, ItemVariant, Item."No.", true, Quantity);
        if UpdateExpirationDate then
            UpdateReservationEntry(Item."No.", LocationWhite.Code, WorkDate());
        CreateAndPostWarehouseReceipt(WarehouseReceiptLine, PurchaseHeader, '', false);
        RegisterWarehouseActivity(
          WarehouseActivityLine."Source Document"::"Purchase Order", PurchaseHeader."No.",
          WarehouseActivityLine."Activity Type"::"Put-away");
        FindRegisteredPutAway(RegisteredWhseActivityLine, Item."No.");
    end;

    local procedure ReclassifyLotNoOnWarehouse(LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Qty: Decimal; LotNo: Code[50]; NewLotNo: Code[50])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        LibraryVariableStorage.Enqueue(ItemTrackingMode::"Lot No. Reclassification");
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(NewLotNo);
        LibraryVariableStorage.Enqueue(Qty);
        CreateWarehouseReclassificationJournal(WarehouseJournalLine, LocationCode, ZoneCode, BinCode, ItemNo, '', Qty);

        LibraryWarehouse.PostWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationCode);
    end;

    local procedure RegisterWarehouseActivity(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; Type: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityNo(WarehouseActivityLine, SourceDocument, SourceNo, Type);
        WarehouseActivityHeader.Get(Type, WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWarehouseActivityWithLotNo(SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20]; Type: Enum "Warehouse Activity Type"; LotNo: Code[50])
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetRange("Source Document", SourceDocument);
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", Type);
        WarehouseActivityLine.ModifyAll("Lot No.", LotNo);

        RegisterWarehouseActivity(SourceDocument, SourceNo, Type);
    end;

    local procedure RegisterPickWithQtyToHandle(var AssemblyHeader: Record "Assembly Header"; Qty: Decimal)
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWhseActivityLine(WarehouseActivityLine, AssemblyHeader);
        repeat
            WarehouseActivityLine.Validate("Qty. to Handle", Qty);
            WarehouseActivityLine.Modify(true);
        until WarehouseActivityLine.Next() = 0;

        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RegisterWarehouseJournalLine(JournalTemplateName: Code[10]; JournalBatchName: Code[10]; LocationCode: Code[10])
    begin
        LibraryVariableStorage.Enqueue(RegisterJournalLines);  // RegisterJournalLines used in ConfirmHandler.
        LibraryVariableStorage.Enqueue(JournalLinesRegistered);  // JournalLinesRegistered used in MessageHandler.
        LibraryWarehouse.RegisterWhseJournalLine(JournalTemplateName, JournalBatchName, LocationCode, false);
    end;

    local procedure ResetDefaultWhseLocation()
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SETRANGE("User ID", USERID);
        WarehouseEmployee.SETRANGE(Default, true);
        WarehouseEmployee.MODIFYALL(Default, false);
    end;

    local procedure RunReportCalculateInventory(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; ItemsNotOnInventory: Boolean)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        Item: Record Item;
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::"Phys. Inventory", true);
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        if ItemNo <> '' then
            Item.SetRange("No.", ItemNo);
        if LocationCode <> '' then
            Item.SetRange("Location Filter", LocationCode);
        if BinCode <> '' then
            Item.SetRange("Bin Filter", BinCode);
        LibraryInventory.CalculateInventory(ItemJournalLine, Item, WorkDate(), ItemsNotOnInventory, false);
    end;

    local procedure RunWarehouseCalculateInventory(var WarehouseJournalLine: Record "Warehouse Journal Line"; ZoneCode: Code[10]; LocationCode: Code[10]; ItemNo: Code[20])
    var
        BinContent: Record "Bin Content";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::"Physical Inventory", LocationWhite.Code);
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        if ZoneCode <> '' then
            BinContent.SetRange("Zone Code", ZoneCode);
        if ItemNo <> '' then
            BinContent.SetRange("Item No.", ItemNo);
        LibraryWarehouse.WhseCalculateInventory(WarehouseJournalLine, BinContent, WorkDate(), LibraryUtility.GenerateGUID(), false);
    end;

    local procedure CalculateInventoryOnWhsePhysInvtJournalPage(var WhsePhysInvtJournal: TestPage "Whse. Phys. Invt. Journal"; ItemsNotOnInventory: Boolean; ItemNo: Code[20]; ZoneCode: Code[10]; BinCode: Code[20])
    begin
        WhsePhysInvtJournal.OpenEdit();
        WhsePhysInvtJournal.CurrentJnlBatchName.Lookup();

        // Enqueue values for WhseCalculateInventoryRequestPageHandler.
        LibraryVariableStorage.Enqueue(ItemsNotOnInventory);
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(ZoneCode);
        LibraryVariableStorage.Enqueue(BinCode);

        WhsePhysInvtJournal."Calculate &Inventory".Invoke(); // Invoke Action17: Calculate Inventory.
        WhsePhysInvtJournal.OK().Invoke();
    end;

    local procedure RunCalculateCountingPeriodOnWarehousePhysicalInventoryJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::"Physical Inventory", LocationCode);
        WarehouseJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        WarehouseJournalBatch.Modify(true);
        WarehouseJournalLine.Init();
        WarehouseJournalLine.Validate("Journal Template Name", WarehouseJournalBatch."Journal Template Name");
        WarehouseJournalLine.Validate("Journal Batch Name", WarehouseJournalBatch.Name);
        WarehouseJournalLine.Validate("Location Code", LocationCode);
        LibraryWarehouse.CalculateCountingPeriodOnWarehousePhysicalInventoryJournal(WarehouseJournalLine);
    end;

    local procedure SetupWarehouseJournalBatchEnvironmentOneLocation(var Location: Record "Location"; var WarehouseEmployee: Record "Warehouse Employee"; var WarehouseJournalTemplate: Record "Warehouse Journal Template"; var WarehouseJournalBatch: Record "Warehouse Journal Batch")
    begin
        CreateLocationWithEmployee(Location, WarehouseEmployee, true, true, true);
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location.Code);
    end;

    local procedure SetupWarehouseJournalBatchEnvironmentTwoLocations(var Location: array[2] of Record "Location"; var WarehouseEmployee: array[2] of Record "Warehouse Employee"; var WarehouseJournalTemplate: Record "Warehouse Journal Template"; var WarehouseJournalBatch: Record "Warehouse Journal Batch")
    begin
        CreateLocationWithEmployee(Location[1], WarehouseEmployee[1], true, true, true);
        CreateLocationWithEmployee(Location[2], WarehouseEmployee[2], false, true, true);
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Location[2].Code);
    end;

    local procedure SetupWarehouseJournalBatchEnvironmentNoBatch(var Location: Record "Location"; var WarehouseEmployee: Record "Warehouse Employee"; var WarehouseJournalTemplate: Record "Warehouse Journal Template"; IsDirectPutAwayAndPickup: Boolean)
    begin
        CreateLocationWithEmployee(Location, WarehouseEmployee, true, true, IsDirectPutAwayAndPickup);
        LibraryWarehouse.CreateWhseJournalTemplate(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
    end;

    local procedure UpdateBinOnWarehouseReceiptLine(WarehouseReceiptLine: Record "Warehouse Receipt Line"; BinCode: Code[20])
    begin
        WarehouseReceiptLine.Validate("Bin Code", BinCode);
        WarehouseReceiptLine.Modify(true);
    end;

    local procedure UpdateItemTrackingLines(var ItemTrackingLines: TestPage "Item Tracking Lines"; TrackingQuantity: Decimal)
    begin
        ItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        ItemTrackingLines."Quantity (Base)".SetValue(TrackingQuantity / 2);
        LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);
    end;

    local procedure UpdatePhysicalInventoryAndRegister(var WarehouseJournalLine: Record "Warehouse Journal Line"; ItemNo: Code[20])
    begin
        FindWarehouseJournalLine(WarehouseJournalLine, ItemNo);
        UpdateQuantityPhysicalInventoryOnWarehouseJournalLine(WarehouseJournalLine, 0);  // Value Important for Difference in Quantity.
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", LocationWhite.Code, true);
    end;

    local procedure UpdateQtyPerInProdOrderComponent(ProdOrderStatus: Enum "Production Order Status"; ProdOrderNo: Code[20]; NewQtyPer: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange(Status, ProdOrderStatus);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Quantity per", NewQtyPer);
        ProdOrderComponent.Modify(true);
    end;

    local procedure UpdateQuantityPhysicalInventoryOnWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; QtyPhysInventory: Decimal)
    begin
        WarehouseJournalLine.Validate("Qty. (Phys. Inventory)", QtyPhysInventory);  // Value Important for Difference in Quantity.
        WarehouseJournalLine.Modify(true);
    end;

    local procedure UpdateReservationEntry(ItemNo: Code[20]; LocationCode: Code[10]; ExpirationDate: Date)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Location Code", LocationCode);
        ReservationEntry.ModifyAll("Expiration Date", ExpirationDate, true);
    end;

    local procedure UpdateWhseItemTrackingLine(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines"; TrackingQuantity: Decimal; NewExpirationDate: Date)
    begin
        WhseItemTrackingLines."Lot No.".AssistEdit();
        WhseItemTrackingLines.Quantity.SetValue(TrackingQuantity / 2);
        WhseItemTrackingLines."New Expiration Date".SetValue(NewExpirationDate);
    end;

    local procedure UpdateFlushingMethodOnItem(var Item: Record Item; FlushingMethod: Enum "Flushing Method")
    begin
        Item.Validate("Flushing Method", FlushingMethod);
        Item.Modify(true);
    end;

    local procedure UpdateProductionBOMNoOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateBOMHeader(ProductionBOMNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMHeader.SetRange("No.", ProductionBOMNo);
        ProductionBOMHeader.FindFirst();
        UpdateBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::"Under Development");
        UpdateBOMLineRoutingLinkCode(ProductionBOMNo, ItemNo, RoutingLinkCode);
        UpdateBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure UpdateBOMStatus(var ProductionBOMHeader: Record "Production BOM Header"; ProductionBOMStatus: Enum "BOM Status")
    begin
        ProductionBOMHeader.Validate(Status, ProductionBOMStatus);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure UpdateItemJnlLineDocNo(JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.ModifyAll("Document No.", LibraryUtility.GenerateGUID());
    end;

    local procedure UpdateInventoryWithWhseItemJournal(var Item: Record Item; Location: Record Location; Quantity: Decimal)
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Create and register the Warehouse Item Journal Line.
        ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch, ItemJournalTemplate.Type::Item, LibraryERM.CreateNoSeriesCode());
        LibraryWarehouse.WarehouseJournalSetup(Location.Code, WarehouseJournalTemplate, WarehouseJournalBatch);
        CreateWarehouseJournalLineWithInBatch(Item, WarehouseJournalLine, WarehouseJournalBatch, Location, Quantity);
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, Location.Code, true);

        // Calculate Warehouse adjustment and post Item Journal.
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        CalculateWhseAdjustmentAndPostCreatedItemJournalLine(Item, ItemJournalBatch);
    end;

    local procedure UpdateBOMLineRoutingLinkCode(ProductionBOMHeaderNo: Code[20]; ItemNo: Code[20]; RoutingLinkCode: Code[10])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        FindProdBOMLine(ProductionBOMLine, ProductionBOMHeaderNo, ItemNo);
        ProductionBOMLine.Validate("Routing Link Code", RoutingLinkCode);
        ProductionBOMLine.Modify(true);
    end;

    local procedure UpdateItemInventory(ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ItemNo, LocationCode, BinCode, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure UpdateWarehouseStockOnBinWithLotNo(Bin: Record Bin; ItemNo: Code[20]; LotNo: Code[50]; Qty: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalLine.DeleteAll();

        LibraryVariableStorage.Enqueue(0);
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryWarehouse.UpdateWarehouseStockOnBin(Bin, ItemNo, Qty, true);
    end;

    local procedure UpdateWarehouseStockOnBinWithLotAndDimensions(Item: Record Item; Bin: Record Bin; LotNo: Code[50]; Qty: Decimal; DimSetID: Integer)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        UpdateWarehouseStockOnBinWithLotNo(Bin, Item."No.", LotNo, Qty);
        CalculateWhseAdjustment(ItemJournalBatch, Item);
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, Item."No.");

        ItemJournalLine.Validate("Dimension Set ID", DimSetID);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalBatch(ItemJournalBatch);
    end;

    local procedure SelectItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; JournalTemplateName: Code[10]; JournalBatchName: Code[10])
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalBatchName);
        ItemJournalLine.FindFirst();
    end;

    local procedure VerifyItemJnlLineAndReservationEntryQty(TrackingSpecification: Record "Tracking Specification"; EntryType: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        ItemJournalLine.SetRange("Item No.", TrackingSpecification."Item No.");
        ItemJournalLine.SetRange("Line No.", TrackingSpecification."Source Ref. No.");
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(
          Quantity, Abs(TrackingSpecification."Quantity (Base)" + TrackingSpecification."Qty. to Handle (Base)"));
        ItemJournalLine.TestField("Entry Type", EntryType);

        ReservationEntry.SetRange("Item No.", TrackingSpecification."Item No.");
        ReservationEntry.SetRange("Source Ref. No.", TrackingSpecification."Source Ref. No.");
        ReservationEntry.SetRange("Lot No.", TrackingSpecification."Lot No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, TrackingSpecification."Quantity (Base)");
        ReservationEntry.TestField("Quantity (Base)", TrackingSpecification."Quantity (Base)");

        ReservationEntry.SetRange("Lot No.", TrackingSpecification."New Lot No.");
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, TrackingSpecification."Qty. to Handle (Base)");
        ReservationEntry.TestField("Quantity (Base)", TrackingSpecification."Qty. to Handle (Base)");
    end;

    local procedure VerifyItemJnlLineQuantity(ItemNo: Code[20]; EntryType: Integer; Qty: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.SetRange("Entry Type", EntryType);
        Assert.RecordCount(ItemJournalLine, 1);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, Qty);
        ItemJournalLine.TestField("Quantity (Base)", Qty);
    end;

    local procedure VerifyBinContent(Bin: Record Bin; ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", Bin."Location Code");
        BinContent.SetRange("Bin Code", Bin.Code);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.FindFirst();
        BinContent.CalcFields("Quantity (Base)");
        BinContent.TestField("Quantity (Base)", ExpectedQuantity);
    end;

    local procedure VerifyInventoryForItem(Item: Record Item; Quantity: Decimal)
    begin
        Item.CalcFields(Inventory);
        Item.TestField(Inventory, Quantity);
    end;

    local procedure VerifyItemLedgerEntry(EntryType: Enum "Item Ledger Entry Type"; ItemNo: Code[20]; LocationCode: Code[10]; Open: Boolean; SerialNo: Code[50]; LotNo: Code[50]; ExpirationDate: Date; Quantity: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange(Open, Open);
        FindItemLedgerEntry(ItemLedgerEntry, EntryType, LocationCode, ItemNo);
        ItemLedgerEntry.TestField(Quantity, Quantity);
        ItemLedgerEntry.TestField("Serial No.", SerialNo);
        ItemLedgerEntry.TestField("Lot No.", LotNo);
        ItemLedgerEntry.TestField("Expiration Date", ExpirationDate);
    end;

    local procedure VerifyItemLedgerEntryDimensions(ItemNo: Code[20]; DimSetID: Integer)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Transfer);
        ItemLedgerEntry.SetRange(Positive, true);
        ItemLedgerEntry.SetRange("Dimension Set ID", DimSetID);
        ItemLedgerEntry.FindFirst();

        ItemLedgerEntry.TestField("Global Dimension 1 Code", FindDimensionSetEntry(DimSetID, GLSetup."Global Dimension 1 Code"));
        ItemLedgerEntry.TestField("Global Dimension 2 Code", FindDimensionSetEntry(DimSetID, GLSetup."Global Dimension 2 Code"));
    end;

    local procedure VerifyValueEntryDimensions(ItemNo: Code[20]; DimSetID: Integer)
    var
        GLSetup: Record "General Ledger Setup";
        ValueEntry: Record "Value Entry";
    begin
        GLSetup.Get();
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Transfer);
        ValueEntry.SetFilter("Item Ledger Entry Quantity", '>0');
        ValueEntry.SetRange("Dimension Set ID", DimSetID);
        ValueEntry.FindFirst();

        ValueEntry.TestField("Global Dimension 1 Code", FindDimensionSetEntry(DimSetID, GLSetup."Global Dimension 1 Code"));
        ValueEntry.TestField("Global Dimension 2 Code", FindDimensionSetEntry(DimSetID, GLSetup."Global Dimension 2 Code"));
    end;

    local procedure VerifyReservationEntry(ItemNo: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; ReservationStatus: Enum "Reservation Status"; ExpectedQty: Decimal; ExpectedLotNo: Code[50])
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", SourceSubtype);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        ReservationEntry.FindFirst();

        ReservationEntry.TestField(Quantity, ExpectedQty);
        ReservationEntry.TestField("Lot No.", ExpectedLotNo);
    end;

    local procedure VerifyReservationQuantity(ReservationStatus: Enum "Reservation Status"; SourceType: Integer; SourceSubtype: Option; SourceID: Code[20]; LotNo: Code[50]; ExpectedQty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Reservation Status", ReservationStatus);
        ReservationEntry.SetRange("Source Type", SourceType);
        ReservationEntry.SetRange("Source Subtype", SourceSubtype);
        ReservationEntry.SetRange("Source ID", SourceID);
        ReservationEntry.SetRange("Lot No.", LotNo);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, ExpectedQty);
    end;

    local procedure VerifyReservationEntryQuantity(ItemNo: Code[20]; LotNo: Code[50]; Qty: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Lot No.", LotNo);
        Assert.RecordCount(ReservationEntry, 1);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, Qty);
        ReservationEntry.TestField("Quantity (Base)", Qty);
    end;

    local procedure VerifyPhysicalInventoryJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        FilterItemJournalLine(ItemJournalLine, ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name", ItemNo);
        ItemJournalLine.SetRange("Location Code", LocationCode);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField("Qty. (Phys. Inventory)", Quantity);
    end;

    local procedure VerifyWarehouseAdjustmentLine(ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemNo);
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWhseAdjustmentLinesWithMultipleUnitOfMeasure(ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FilterItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemNo);
        ItemJournalLine.SetRange("Unit of Measure Code", UnitOfMeasureCode);
        ItemJournalLine.FindFirst();
        ItemJournalLine.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseEntry(PurchaseLine: Record "Purchase Line")
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Source No.", PurchaseLine."Document No.");
        WarehouseEntry.SetRange("Item No.", PurchaseLine."No.");
        WarehouseEntry.FindSet();
        WarehouseEntry.TestField(Quantity, PurchaseLine."Qty. to Receive" / 2);  // Verify Partial Quantity.
        WarehouseEntry.Next();
        WarehouseEntry.TestField(Quantity, PurchaseLine."Qty. to Receive" / 2);  // Verify Partial Quantity.
    end;

    local procedure VerifyWhseAdjustmentLinesnotExist(ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; Quantity: Decimal): Boolean
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FilterItemJournalLine(ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemNo);
        ItemJournalLine.SetRange(Quantity, Quantity);
        exit(not ItemJournalLine.IsEmpty());
    end;

    local procedure VerifyWarehouseEntryForCoutingPeriod(WarehouseJournalLine: Record "Warehouse Journal Line"; EntryType: Option; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        FIlterWarehouseEntries(WarehouseEntry, EntryType, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code");
        WarehouseEntry.SetRange("Journal Template Name", WarehouseJournalLine."Journal Template Name");
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Quantity, Quantity);
        WarehouseEntry.TestField("Phys Invt Counting Period Code", WarehouseJournalLine."Phys Invt Counting Period Code");
        WarehouseEntry.TestField("Phys Invt Counting Period Type", WarehouseJournalLine."Phys Invt Counting Period Type");
    end;

    local procedure VerifyWarehouseEntriesForLotAndSerialNo(WarehouseJournalLine: Record "Warehouse Journal Line"; EntryType: Option; Quantity: Decimal; LotNoExpected: Boolean)
    var
        WarehouseEntry: Record "Warehouse Entry";
        TrackingQuantity: Decimal;
    begin
        FIlterWarehouseEntries(WarehouseEntry, EntryType, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code");
        WarehouseEntry.FindSet();
        TrackingQuantity := WarehouseJournalLine.Quantity;
        repeat
            WarehouseEntry.TestField("Serial No.", Format(TrackingQuantity));
            if LotNoExpected then
                WarehouseEntry.TestField("Lot No.", Format(TrackingQuantity))
            else
                WarehouseEntry.TestField("Lot No.", '');
            WarehouseEntry.TestField(Quantity, Quantity);
            TrackingQuantity -= 1;
        until WarehouseEntry.Next() = 0;
    end;

    local procedure VerifyWarehouseEntryForWhseJournal(RegisteredWhseActivityLine: Record "Registered Whse. Activity Line"; SerialNo: Code[50]; LotNo: Code[50]; Quantity: Decimal; NextLine: Boolean)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        FIlterWarehouseEntries(
          WarehouseEntry, WarehouseEntry."Entry Type"::Movement, RegisteredWhseActivityLine."Item No.",
          RegisteredWhseActivityLine."Location Code");
        WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::"Whse. Journal");
        WarehouseEntry.SetRange("Lot No.", LotNo);
        WarehouseEntry.FindSet();
        WarehouseEntry.TestField(Quantity, -Quantity);
        if NextLine then begin
            WarehouseEntry.Next();
            WarehouseEntry.TestField(Quantity, Quantity);
        end;
        WarehouseEntry.TestField("Variant Code", RegisteredWhseActivityLine."Variant Code");
        WarehouseEntry.TestField("Bin Code", RegisteredWhseActivityLine."Bin Code");
        WarehouseEntry.TestField("Serial No.", SerialNo);
    end;

    local procedure VerifyWarehouseEntryWithBlockedItem(WarehouseJournalLine: Record "Warehouse Journal Line"; EntryType: Option; Quantity: Decimal)
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        FIlterWarehouseEntries(WarehouseEntry, EntryType, WarehouseJournalLine."Item No.", WarehouseJournalLine."Location Code");
        WarehouseEntry.FindFirst();
        WarehouseEntry.TestField(Quantity, Quantity);
    end;

    local procedure VerifyWarehouseEntryForZeroQty(ItemNo: Code[20]; BinCode: Code[20])
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Item No.", ItemNo);
        WarehouseEntry.SetRange("Bin Code", BinCode);
        WarehouseEntry.CalcSums(Quantity, "Qty. (Base)");
        WarehouseEntry.TestField(Quantity, 0);
        WarehouseEntry.TestField("Qty. (Base)", 0);
    end;

    local procedure VerifyWarehousePhysicalJournalLine(WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; ItemNo: Code[20])
    begin
        FilterWarehouseJournalLine(
          WarehouseJournalLine, WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name",
          WarehouseJournalLine."Location Code");
        WarehouseJournalLine.FindFirst();
        WarehouseJournalLine.TestField("Item No.", ItemNo);
        WarehouseJournalLine.TestField("Bin Code", Bin.Code);
        WarehouseJournalLine.TestField("Zone Code", Bin."Zone Code");
    end;

    local procedure VerifyWarehousePhysicalJournalLineForLot(WarehouseJournalLine: Record "Warehouse Journal Line"; LotNo: Code[50]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        FilterWarehouseJournalLine(
          WarehouseJournalLine, WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name",
          WarehouseJournalLine."Location Code");
        WarehouseJournalLine.SetRange("Lot No.", LotNo);
        WarehouseJournalLine.FindFirst();
        WarehouseJournalLine.TestField("Item No.", ItemNo);
        WarehouseJournalLine.TestField("Qty. (Phys. Inventory)", Quantity);
    end;

    local procedure VerifyWarehousePhysicalJournalLineExist(WarehouseJournalLine: Record "Warehouse Journal Line"; ZoneCode: Code[20]; ItemNo: Code[20]): Boolean
    begin
        FilterWarehouseJournalLine(
          WarehouseJournalLine, WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name",
          WarehouseJournalLine."Location Code");
        WarehouseJournalLine.SetRange("Zone Code", ZoneCode);
        WarehouseJournalLine.SetRange("Item No.", ItemNo);
        exit(WarehouseJournalLine.FindFirst())
    end;

    local procedure VerifyWhsePhysJournalLine(ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; QtyCalculated: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalLine.SetRange("Zone Code", ZoneCode);
        WarehouseJournalLine.SetRange("Bin Code", BinCode);
        WarehouseJournalLine.SetRange("Item No.", ItemNo);
        Assert.IsTrue(WarehouseJournalLine.FindFirst(), StrSubstNo(WarehouseLineMustExistErr, ZoneCode, BinCode, ItemNo));
        Assert.AreEqual(QtyCalculated, WarehouseJournalLine."Qty. (Calculated)", QtyCalculatedErr);
    end;

    local procedure VerifyLastWarehouseRegisterNo(LastWarehouseRegisterNo: Integer)
    var
        WarehouseRegister: Record "Warehouse Register";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseRegister.FindLast();
        WarehouseRegister.TestField("No.", LastWarehouseRegisterNo);
        if WarehouseRegister."From Entry No." > WarehouseRegister."To Entry No." then
            exit; // no entries created
        WarehouseEntry.SetRange("Entry No.", WarehouseRegister."From Entry No.", WarehouseRegister."To Entry No.");
        WarehouseEntry.FindFirst();
        Assert.AreEqual(WarehouseRegister."No.", WarehouseEntry."Warehouse Register No.", 'Wrong Warehouse Register No.');
    end;

    local procedure CreateBinForPickZone(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        FindZone(Zone, LocationCode, LibraryWarehouse.SelectBinType(false, false, true, true));
        LibraryWarehouse.CreateBin(Bin, LocationCode, LibraryUtility.GenerateGUID(), Zone.Code, Zone."Bin Type Code");
    end;

    local procedure SetDirectPutAwayOnLocation()
    var
        Location: Record Location;
    begin
        Location.SetFilter(Code, '<>%1', LocationWhite.Code);
        Location.SetRange("Directed Put-away and Pick", true);
        Location.ModifyAll("Directed Put-away and Pick", false);
    end;

    local procedure VerifyWarehousePhysicalJournalLineExist(ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; LotNo: Code[50]; PackageNo: Code[50]; QtyCalculated: Decimal)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalLine.SetRange("Zone Code", ZoneCode);
        WarehouseJournalLine.SetRange("Bin Code", BinCode);
        WarehouseJournalLine.SetRange("Item No.", ItemNo);
        WarehouseJournalLine.SetRange("Lot No.", LotNo);
        WarehouseJournalLine.SetRange("Package No.", PackageNo);
        Assert.IsTrue(WarehouseJournalLine.FindFirst(), StrSubstNo(WarehouseLineMustExistErr, ZoneCode, BinCode, ItemNo));
        Assert.AreEqual(QtyCalculated, WarehouseJournalLine."Qty. (Calculated)", QtyCalculatedErr);
    end;

    local procedure EnterTrackingInfo(LotNo: Integer; PackageNo: Integer; Qty: Integer)
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PackageNo);
        LibraryVariableStorage.Enqueue(Qty);
    end;

    local procedure CreateAndRegisterWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; LocationCode: Code[10]; ZoneCode: Code[10]; BinCode: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(
            WarehouseJournalBatch, WarehouseJournalTemplate.Type::Item, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, ZoneCode, BinCode,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        WarehouseJournalLine.OpenItemTrackingLines();
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, false);
    end;

    local procedure CreateItemTrackingCode(var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, false, true, true);
        ItemTrackingCode.Validate("Lot Warehouse Tracking", true);
        ItemTrackingCode.Validate("Package Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
    end;

    local procedure CreateWhseJournalLineWithSerialTracking(
            WarehouseJournalBatch: Record "Warehouse Journal Batch";
            Bin: Record Bin;
            ItemNo: Code[20];
            Qty: Decimal;
            SerialNo: Code[50];
            ExpirationDate: Date)
    var
        WhseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
            WhseJournalLine,
            WarehouseJournalBatch."Journal Template Name",
            WarehouseJournalBatch.Name,
            Bin."Location Code",
            Bin."Zone Code",
            Bin.Code,
            WhseJournalLine."Entry Type"::"Positive Adjmt.",
            ItemNo,
            Qty);

        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(Qty);
        WhseJournalLine.OpenItemTrackingLines();

        WhseItemTrackingLine.SetRange("Serial No.", SerialNo);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure CreateWhseJournalLineWithLotTracking(
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        Bin: Record Bin;
        ItemNo: Code[20];
        Qty: Decimal;
        LotNo: Code[50];
        ExpirationDate: Date)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJournalLine,
            WarehouseJournalBatch."Journal Template Name",
            WarehouseJournalBatch.Name,
            Bin."Location Code",
            Bin."Zone Code",
            Bin.Code,
            WarehouseJournalLine."Entry Type"::"Positive Adjmt.",
            ItemNo,
            Qty);

        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(Qty);
        WarehouseJournalLine.OpenItemTrackingLines();

        WhseItemTrackingLine.SetRange("Lot No.", LotNo);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.Validate("Expiration Date", ExpirationDate);
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure CreateItemJournalToCalculateWhseAdjustment(
        var ItemJournalTemplate: Record "Item Journal Template";
        var ItemJournalBatch: Record "Item Journal Batch";
        var Item: Record Item)
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        AssignNoSeriesForItemJournalBatch(ItemJournalBatch, LibraryUtility.GetGlobalNoSeriesCode());
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure AssignNoSeriesForItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; NoSeries: Code[20])
    begin
        ItemJournalBatch.Find();
        ItemJournalBatch.Validate("No. Series", NoSeries);
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateAndReleaseSalesOrder(
        var SalesHeader: Record "Sales Header";
        var SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, LibraryRandom.RandInt(0));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure AssignSerialNoLotNoAndQtyToHandleInWhseActivityLines(
        var WhseActivityLine: Record "Warehouse Activity Line";
        ItemNo: Code[20];
        SerialNo: Code[50];
        LotNo: Code[50])
    begin
        WhseActivityLine.SetRange("Item No.", ItemNo);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Take);
        WhseActivityLine.FindFirst();
        WhseActivityLine.Validate("Serial No.", SerialNo);
        WhseActivityLine.Validate("Lot No.", LotNo);
        WhseActivityLine.Validate("Qty. to Handle", LibraryRandom.RandInt(0));
        WhseActivityLine.Modify(true);

        WhseActivityLine.SetRange("Item No.", ItemNo);
        WhseActivityLine.SetRange("Action Type", WhseActivityLine."Action Type"::Place);
        WhseActivityLine.FindFirst();
        WhseActivityLine.Validate("Serial No.", SerialNo);
        WhseActivityLine.Validate("Lot No.", LotNo);
        WhseActivityLine.Validate("Qty. to Handle", LibraryRandom.RandInt(0));
        WhseActivityLine.Modify(true);
    end;

    local procedure CreateLocationWithWarehouseEmployeeSetup(var Location: Record Location; var WarehouseEmployee: Record "Warehouse Employee")
    begin
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CalculateInventoryFromWhsePhysInvJournalPage(LocationCode: Code[10]; ItemNo: Code[20])
    var
        WhsePhysInvtJournal: TestPage "Whse. Phys. Invt. Journal";
    begin
        WhsePhysInvtJournal.OpenEdit();
        LibraryVariableStorage.Enqueue(LocationCode);
        LibraryVariableStorage.Enqueue(ItemNo);
        WhsePhysInvtJournal."Calculate &Inventory".Invoke();
        WhsePhysInvtJournal.Close();
    end;

    local procedure EnterTrackingInfoWithExpirationDate(
        LotNo: Integer;
        PackageNo: Integer;
        Qty: Integer; ExpDate: Date)
    begin
        LibraryVariableStorage.Enqueue(LotNo);
        LibraryVariableStorage.Enqueue(PackageNo);
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(ExpDate);
    end;

    local procedure CreateAndRegisterWarehouseJournalLineWithExpirationDate(
        var WarehouseJournalLine: Record "Warehouse Journal Line";
        LocationCode: Code[10];
        ZoneCode: Code[10];
        BinCode: Code[20];
        ItemNo: Code[20];
        Qty: Decimal)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.CreateWarehouseJournalBatch(
            WarehouseJournalBatch,
            WarehouseJournalTemplate.Type::Item,
            LocationCode);

        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name,
            LocationCode, ZoneCode, BinCode, WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);

        WarehouseJournalLine.OpenItemTrackingLines();

        UpdateExpirationDateOnWhseItemTrackingLine(LocationCode, ItemNo);

        LibraryWarehouse.RegisterWhseJournalLine(
            WarehouseJournalBatch."Journal Template Name",
            WarehouseJournalBatch.Name,
            LocationCode,
            false);
    end;

    local procedure UpdateExpirationDateOnWhseItemTrackingLine(LocationCode: Code[10]; ItemNo: Code[20])
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
    begin
        WhseItemTrackingLine.SetRange("Location Code", LocationCode);
        WhseItemTrackingLine.SetRange("Item No.", ItemNo);
        WhseItemTrackingLine.FindFirst();
        WhseItemTrackingLine.Validate("Expiration Date", LibraryVariableStorage.DequeueDate());
        WhseItemTrackingLine.Modify(true);
    end;

    local procedure VerifyExpirationDateOnWarehousePhysicalJournalLine(
        ZoneCode: Code[10];
        BinCode: Code[20];
        ItemNo: Code[20];
        LotNo: Code[50];
        ExpDate: Date)
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalLine.SetRange("Zone Code", ZoneCode);
        WarehouseJournalLine.SetRange("Bin Code", BinCode);
        WarehouseJournalLine.SetRange("Item No.", ItemNo);
        WarehouseJournalLine.SetRange("Lot No.", LotNo);
        WarehouseJournalLine.FindFirst();

        asserterror WarehouseJournalLine.Validate("Expiration Date", 0D);
        Assert.IsTrue((WarehouseJournalLine."Expiration Date" = ExpDate), '');
    end;

    local procedure CreatePurchaseItemwithTracking(var Item: Record Item; var ItemTrackingCode: Record "Item Tracking Code")
    begin
        LibraryInventory.CreateItemTrackingCode(ItemTrackingCode);
        ItemTrackingCode.Validate("SN Specific Tracking", true);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);

        LibraryInventory.CreateTrackedItem(Item, '', '', ItemTrackingCode.Code);
        Item.Validate("Replenishment System", Item."Replenishment System"::Purchase);
        Item.Modify(true);
    end;

    local procedure CreateAssemblyItemwithBOM(var Item: Record Item; var AssemblyItem: Record Item)
    begin
        LibraryInventory.CreateItem(AssemblyItem);
        AssemblyItem.Validate("Replenishment System", AssemblyItem."Replenishment System"::Assembly);
        AssemblyItem.Validate("Assembly Policy", Enum::"Assembly Policy"::"Assemble-to-Order");
        AssemblyItem.Modify(true);

        CreateAssemblyBomComponent(AssemblyItem."No.", Item."No.");
    end;

    local procedure CreateAssemblyBomComponent(ParentItemNo: Code[20]; BomItemNo: Code[20])
    var
        BomComponent: Record "BOM Component";
        RecRef: RecordRef;

    begin
        BomComponent.Init();
        BomComponent.Validate("Parent Item No.", ParentItemNo);
        RecRef.GetTable(BomComponent);
        BomComponent.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, BomComponent.FieldNo("Line No.")));
        BomComponent.Validate(Type, BomComponent.Type::Item);
        BomComponent.Validate("No.", BomItemNo);
        BomComponent.Validate("Quantity per", LibraryRandom.RandInt(1));
        BomComponent.Insert(true);
    end;

    local procedure CreatePurchaseOrderWithItemTracking(
        var PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
        Quantity: Decimal;
        SerialNo: code[20])
    var
        PurchaseLine: Record "Purchase Line";
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Order", LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Location Code", LocationWhite.Code);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", Quantity);

        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);
        LibraryVariableStorage.Enqueue(SerialNo);
        LibraryVariableStorage.Enqueue(Quantity);
        PurchaseLine.OpenItemTrackingLines();
    end;

    local procedure CreateAndPostWarehouseReceiptAndPutAway(PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);

        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseReceiptLine.FindFirst();

        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);

        RegisterWarehouseActivity(
            WarehouseActivityLine."Source Document"::"Purchase Order",
            PurchaseHeader."No.",
            WarehouseActivityLine."Activity Type"::"Put-away");
    end;

    local procedure CreateSalesOrderAndRelease(var SalesHeader: Record "Sales Header"; Item: Record Item; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        SalesHeader.Validate("Due Date", WorkDate() + 1);
        SalesHeader.Modify(true);

        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", Quantity);
        SalesLine.TestField("Qty. to Assemble to Order");
        SalesLine.Validate("Location Code", LocationWhite.Code);
        SalesLine.Modify(true);

        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateWarehouseShipmentAndPickWithRegister(
        var SalesHeader: Record "Sales Header";
        var WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        var WhseActivityLine: Record "Warehouse Activity Line";
        SerialNo: code[50]);
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehousePickPage: TestPage "Warehouse Pick";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);

        WarehouseShipmentHeader.Get(
            LibraryWarehouse.FindWhseShipmentNoBySourceDoc(
                DATABASE::"Sales Line",
                SalesHeader."Document Type".AsInteger(),
                SalesHeader."No."));

        LibraryWarehouse.CreatePick(WarehouseShipmentHeader);
        Commit();

        WhseActivityLine.SetRange("Whse. Document Type", WhseActivityLine."Whse. Document Type"::Shipment);
        WhseActivityLine.SetRange("Whse. Document No.", WarehouseShipmentHeader."No.");
        WhseActivityLine.FindSet();
        repeat
            WhseActivityLine.Validate("Serial No.", SerialNo);
            WhseActivityLine.UpdateExpirationDate(WhseActivityLine.FieldNo("Serial No."));
            WhseActivityLine.Modify(true);
        until WhseActivityLine.Next() = 0;

        WarehouseActivityHeader.Get(WhseActivityLine."Activity Type", WhseActivityLine."No.");
        WarehousePickPage.OpenEdit();
        WarehousePickPage.GotoRecord(WarehouseActivityHeader);
        WarehousePickPage."Autofill Qty. to Handle".Invoke();
        WarehousePickPage.Close();

        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure FindSalesShipmentLine(var SalesShipmentLine: Record "Sales Shipment Line"; OrderNo: Code[20])
    begin
        SalesShipmentLine.SetRange("Order No.", OrderNo);
        SalesShipmentLine.FindFirst();
    end;

    local procedure UpdateQtyToShipInWhseShipment(WhseShipmentNo: Code[20]; NewQty: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        WarehouseShipmentLine.SetRange("No.", WhseShipmentNo);
        WarehouseShipmentLine.FindSet();
        repeat
            WarehouseShipmentLine.Validate("Qty. to Ship", NewQty);
            WarehouseShipmentLine.Modify(true);
        until WarehouseShipmentLine.Next() = 0;
    end;

    local procedure CreateWarehouseReclassificationJournal(
        var WarehouseJournalLine: Record "Warehouse Journal Line";
        WareohuseActivityLine: Record "Warehouse Activity Line";
        LocationCode: Code[10];
        ItemNo: Code[20];
        Qty: Decimal)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
        FromZoneCode: Code[10];
        FromBinCode: Code[20];
        ToZoneCode: Code[10];
        ToBinCode: Code[20];
        TrackingOption: Option AssignSerialNo,AssignLotNo,VerifyLotNo;
    begin
        FindBinCodeandZone(WareohuseActivityLine, FromZoneCode, FromBinCode, ToZoneCode, ToBinCode);

        LibraryWarehouse.CreateWarehouseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Type::Reclassification, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
            WarehouseJournalLine,
            WarehouseJournalBatch."Journal Template Name",
            WarehouseJournalBatch.Name,
            LocationCode,
            FromZoneCode,
            FromBinCode,
            WarehouseJournalLine."Entry Type"::Movement,
            ItemNo,
            Qty);

        WarehouseJournalLine.Validate("From Zone Code", FromZoneCode);
        WarehouseJournalLine.Validate("From Bin Code", FromBinCode);
        WarehouseJournalLine.Validate("To Zone Code", ToZoneCode);
        WarehouseJournalLine.Validate("To Bin Code", ToBinCode);
        WarehouseJournalLine.Modify(true);

        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);
        LibraryVariableStorage.Enqueue(LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(Qty);
        WarehouseJournalLine.OpenItemTrackingLines();
    end;

    local procedure FindBinCodeandZone(
        WareohuseActivityLine: Record "Warehouse Activity Line";
        var FromZoneCode: Code[10];
        var FromBinCode: Code[20];
        var ToZoneCode: Code[10];
        var ToBinCode: Code[20])
    var
        WarehouseEnt: Record "Warehouse Entry";
    begin
        WarehouseEnt.SetRange("Entry Type", WarehouseEnt."Entry Type"::Movement);
        WarehouseEnt.SetRange("Whse. Document Type", WarehouseEnt."Whse. Document Type"::Shipment);
        WarehouseEnt.SetRange("Whse. Document No.", WareohuseActivityLine."Whse. Document No.");
        WarehouseEnt.SetRange("Whse. Document Line No.", WareohuseActivityLine."Whse. Document Line No.");
        WarehouseEnt.SetFilter(Quantity, '<%1', 0);
        if WarehouseEnt.FindFirst() then begin
            ToZoneCode := WarehouseEnt."Zone Code";
            ToBinCode := WarehouseEnt."Bin Code";
        end;

        Clear(WarehouseEnt);
        WarehouseEnt.SetRange("Entry Type", WarehouseEnt."Entry Type"::Movement);
        WarehouseEnt.SetRange("Whse. Document Type", WarehouseEnt."Whse. Document Type"::Shipment);
        WarehouseEnt.SetRange("Whse. Document No.", WareohuseActivityLine."Whse. Document No.");
        WarehouseEnt.SetRange("Whse. Document Line No.", WareohuseActivityLine."Whse. Document Line No.");
        WarehouseEnt.SetFilter(Quantity, '>%1', 0);
        if WarehouseEnt.FindFirst() then begin
            FromZoneCode := WarehouseEnt."Zone Code";
            FromBinCode := WarehouseEnt."Bin Code";
        end;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ConfirmMessageText: Text;
    begin
        ConfirmMessageText := LibraryVariableStorage.DequeueText();
        Assert.IsTrue(StrPos(ConfirmMessage, ConfirmMessageText) > 0, ConfirmMessage);
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYesNo(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.ExpectedConfirm(LibraryVariableStorage.DequeueText(), ConfirmMessage);
        Reply := LibraryVariableStorage.DequeueBoolean();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure DummyConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculatePhysicalInventoryCountingHandler(var CalculatePhysInvtCounting: TestRequestPage "Calculate Phys. Invt. Counting")
    begin
        CalculatePhysInvtCounting.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingQuantity: Variant;
        TrackingQuantity2: Integer;
    begin
        TrackingQuantity2 := 0;  // Assign Variable.
        case LibraryVariableStorage.DequeueInteger() of
            TrackingAction::VerifyTracking:
                begin
                    ItemTrackingLines.Last();
                    LibraryVariableStorage.Dequeue(TrackingQuantity);
                    TrackingQuantity2 := TrackingQuantity;
                    repeat
                        ItemTrackingLines."Lot No.".AssertEquals(TrackingQuantity2);
                        TrackingQuantity2 -= 1;
                    until ItemTrackingLines.Previous();
                end;
            TrackingAction::AssignLotNo:
                ItemTrackingLines."Assign Lot No.".Invoke();
            TrackingAction::SetNewLotNoWithQty:
                begin
                    ItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    ItemTrackingLines."Quantity (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                    ItemTrackingLines."Qty. to Invoice (Base)".SetValue(LibraryVariableStorage.DequeueDecimal());
                end;
            TrackingAction::AssistEdit:
                begin
                    ItemTrackingLines."Lot No.".AssistEdit();
                    LibraryVariableStorage.Enqueue(ItemTrackingLines."Lot No.".Value);  // Using LotNo for Verification as Index 1 in Queque.
                end;
            TrackingAction::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            TrackingAction::AssignMultipleLotNo:
                begin
                    TrackingQuantity2 := ItemTrackingLines.Quantity3.AsDEcimal();
                    UpdateItemTrackingLines(ItemTrackingLines, TrackingQuantity2);
                    ItemTrackingLines.Next();
                    UpdateItemTrackingLines(ItemTrackingLines, TrackingQuantity2);
                end;
            TrackingAction::SelectEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines."New Expiration Date".SetValue(WorkDate());
                end;
            TrackingAction::EditSerialNo:
                ItemTrackingLines."Serial No.".SetValue(LibraryUtility.GenerateGUID());
            TrackingAction::AssignSerialAndLot:
                begin
                    TrackingQuantity2 := ItemTrackingLines.Quantity3.AsDEcimal();
                    ItemTrackingLines.First();
                    repeat
                        ItemTrackingLines."Lot No.".SetValue(Format(TrackingQuantity2));
                        ItemTrackingLines."Serial No.".SetValue(Format(TrackingQuantity2));
                        ItemTrackingLines."Quantity (Base)".SetValue(1);
                        TrackingQuantity2 -= 1;
                        ItemTrackingLines.Next();
                    until TrackingQuantity2 = 0;
                end;
            TrackingAction::SelectEntriesWithLot:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines."New Lot No.".SetValue(LibraryUtility.GenerateGUID());
                end;
            TrackingAction::SelectEntriesWithNewSerialNo:
                begin
                    ItemTrackingLines."Select Entries".Invoke();
                    ItemTrackingLines."New Serial No.".SetValue(LibraryUtility.GenerateGUID());
                end;
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        DequeueMessage: Variant;
        MessageText: Text[1024];
    begin
        LibraryVariableStorage.Dequeue(DequeueMessage);
        MessageText := DequeueMessage;
        Assert.IsTrue(StrPos(Message, MessageText) > 0, Message);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure DummyMessageHandler(Message: Text[1024])
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PhysicalInventoryItemSelectionHandler(var PhysInvtItemSelection: TestPage "Phys. Invt. Item Selection")
    var
        ItemNo: Variant;
        NextCountingStartDateVar: Variant;
        NextCountingEndDateVar: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        PhysInvtItemSelection.FILTER.SetFilter("Item No.", ItemNo);
        PhysInvtItemSelection.First();
        LibraryVariableStorage.Dequeue(NextCountingStartDateVar);
        LibraryVariableStorage.Dequeue(NextCountingEndDateVar);
        PhysInvtItemSelection."Next Counting Start Date".AssertEquals(NextCountingStartDateVar);
        PhysInvtItemSelection."Next Counting End Date".AssertEquals(NextCountingEndDateVar);
        PhysInvtItemSelection.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        AssignSerialAndLot: Variant;
        LotNoBlank: Variant;
        TrackingAction: Variant;
        TrackingAction2: Option " ",VerifyTracking,AssignLotNo,AssistEdit,AssignSerialNo,AssitEditNewSerialNoExpDate,AssignMultipleLotNo,MultipleExpirationDate,SelectEntries,AssitEditSerialNoAndRemoveExpDate,EditSerialNo,AssitEditLotNo,AssitEditNewLotNoExpDate,AssignSerialAndLot,AssignNewSerialAndLotNo;
        AssignSerialAndLot2: Boolean;
        LotNoBlank2: Boolean;
        TrackingQuantity: Decimal;
        LotNo: Code[50];
    begin
        LibraryVariableStorage.Dequeue(TrackingAction);
        TrackingAction2 := TrackingAction;
        LibraryVariableStorage.Dequeue(LotNoBlank);
        LotNoBlank2 := LotNoBlank;
        LibraryVariableStorage.Dequeue(AssignSerialAndLot);
        AssignSerialAndLot2 := AssignSerialAndLot;

        case TrackingAction2 of
            TrackingAction2::AssignLotNo:
                begin
                    WhseItemTrackingLines."Lot No.".SetValue(LibraryRandom.RandInt(10));  // Taking Random Value for Lot No.
                    WhseItemTrackingLines.Quantity.SetValue(WhseItemTrackingLines.Quantity3.AsDEcimal());
                end;
            TrackingAction2::AssitEditNewSerialNoExpDate:
                begin
                    WhseItemTrackingLines."Serial No.".AssistEdit();
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Serial No.".Value);
                    WhseItemTrackingLines."New Serial No.".SetValue(LibraryUtility.GenerateGUID());
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."New Serial No.".Value);
                    WhseItemTrackingLines."New Expiration Date".SetValue(WorkDate());
                end;
            TrackingAction2::AssitEditNewLotNoExpDate:
                begin
                    WhseItemTrackingLines."Lot No.".AssistEdit();
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Lot No.".Value);
                    WhseItemTrackingLines."New Lot No.".SetValue(LibraryUtility.GenerateGUID());
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."New Lot No.".Value);
                    WhseItemTrackingLines."New Expiration Date".SetValue(WorkDate());
                end;
            TrackingAction2::AssignMultipleLotNo:
                begin
                    LibraryVariableStorage.Dequeue(LotNoBlank);
                    LotNo := LotNoBlank;
                    WhseItemTrackingLines."Lot No.".AssistEdit();
                    WhseItemTrackingLines."New Lot No.".SetValue(LotNo);
                    WhseItemTrackingLines."New Expiration Date".SetValue(WorkDate());
                end;
            TrackingAction2::MultipleExpirationDate:
                begin
                    TrackingQuantity := WhseItemTrackingLines.Quantity3.AsDEcimal();
                    UpdateWhseItemTrackingLine(WhseItemTrackingLines, TrackingQuantity, WorkDate());
                    WhseItemTrackingLines.Next();
                    UpdateWhseItemTrackingLine(
                      WhseItemTrackingLines, TrackingQuantity, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
                end;
            TrackingAction2::AssitEditSerialNoAndRemoveExpDate:
                begin
                    WhseItemTrackingLines."Serial No.".AssistEdit();
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Serial No.".Value);
                    WhseItemTrackingLines.Quantity.SetValue(1);
                    WhseItemTrackingLines."New Expiration Date".SetValue(0D);
                end;
            TrackingAction2::AssitEditLotNo:
                WhseItemTrackingLines."Lot No.".AssistEdit();
            TrackingAction2::AssignNewSerialAndLotNo:
                begin
                    WhseItemTrackingLines."Serial No.".AssistEdit();
                    WhseItemTrackingLines.Quantity.SetValue(0);
                    WhseItemTrackingLines."Lot No.".AssistEdit();
                    WhseItemTrackingLines."New Serial No.".SetValue(LibraryUtility.GenerateGUID());
                    WhseItemTrackingLines."New Lot No.".SetValue(LibraryUtility.GenerateGUID());
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Serial No.".Value);
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."New Serial No.".Value);
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."Lot No.".Value);
                    LibraryVariableStorage.Enqueue(WhseItemTrackingLines."New Lot No.".Value)
                end;
        end;

        if LotNoBlank2 then
            WhseItemTrackingLines."Lot No.".SetValue('');

        if AssignSerialAndLot2 then begin
            TrackingQuantity := WhseItemTrackingLines.Quantity3.AsDEcimal();
            WhseItemTrackingLines.First();
            repeat
                WhseItemTrackingLines."Serial No.".SetValue(Format(TrackingQuantity));
                WhseItemTrackingLines."Lot No.".SetValue(Format(TrackingQuantity));
                WhseItemTrackingLines.Quantity.SetValue(1);
                TrackingQuantity -= 1;
                WhseItemTrackingLines.Next();
            until TrackingQuantity = 0;
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        TrackingMode: Option;
    begin
        TrackingMode := LibraryVariableStorage.DequeueInteger();
        case TrackingMode of
            ItemTrackingMode::"Lot No":
                begin
                    WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    WhseItemTrackingLines.Quantity.SetValue(1);
                end;
            ItemTrackingMode::"Serial No":
                begin
                    WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
                    WhseItemTrackingLines.Quantity.SetValue(1);
                end;
            ItemTrackingMode::"Lot No. Reclassification":
                begin
                    WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    WhseItemTrackingLines."New Lot No.".SetValue(LibraryVariableStorage.DequeueText());
                    WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
                end;
        end;

        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandlerTwoLots(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        WhseItemTrackingLines.Next();
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandlerTwoLotsAndPackages(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        Counter: Integer;
    begin
        for Counter := 1 to LibraryVariableStorage.DequeueInteger() do begin
            WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueInteger());
            WhseItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueInteger());
            WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());
            WhseItemTrackingLines.Next();
        end;
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
        NoOfSN: Integer;
        i: Integer;
    begin
        NoOfSN := LibraryVariableStorage.DequeueInteger();
        for i := 1 to NoOfSN do begin
            WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
            WhseItemTrackingLines.Quantity.SetValue(1);
            WhseItemTrackingLines.Next();
        end;
    end;

    [ModalPageHandler]
    procedure WhseItemTrackingLinesZeroQtyModalPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(ConfirmWhenExitingQst);
        LibraryVariableStorage.Enqueue(false);
        WhseItemTrackingLines.OK().Invoke();

        WhseItemTrackingLines.Quantity.SetValue(1);
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        TrackingMode: Option;
    begin
        TrackingMode := LibraryVariableStorage.DequeueInteger();
        ItemTrackingLines.Last();
        case TrackingMode of
            ItemTrackingMode::"Lot No":
                ItemTrackingLines."Lot No.".AssertEquals(LibraryVariableStorage.DequeueText());
            ItemTrackingMode::"Serial No":
                ItemTrackingLines."Serial No.".AssertEquals(LibraryVariableStorage.DequeueText());
        end;
        ItemTrackingLines."Quantity (Base)".AssertEquals(1);
        Assert.IsFalse(ItemTrackingLines.Previous(), ExcessiveItemTrackingErr);
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseJournalBatchesListHandler(var WhseJournalBatchesList: TestPage "Whse. Journal Batches List")
    begin
        WhseJournalBatchesList.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateInventoryPageHandler(var CalculateInventory: TestRequestPage "Calculate Inventory")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);
        CalculateInventory.DocumentNo.SetValue(ItemNo);
        CalculateInventory.Item.SetFilter("No.", ItemNo);
        CalculateInventory.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseCalculateInventoryRequestPageHandler(var WhseCalculateInventory: TestRequestPage "Whse. Calculate Inventory")
    var
        ZoneCode: Variant;
        BinCode: Variant;
        ItemsNotOnInventory: Variant;
        ItemNo: Variant;
        Zone: Text;
        Bin: Text;
    begin
        LibraryVariableStorage.Dequeue(ItemsNotOnInventory);
        LibraryVariableStorage.Dequeue(ItemNo);
        LibraryVariableStorage.Dequeue(ZoneCode);
        LibraryVariableStorage.Dequeue(BinCode);
        Zone := ZoneCode;
        Bin := BinCode;

        WhseCalculateInventory.WhseDocumentNo.SetValue(LibraryUtility.GetGlobalNoSeriesCode());
        WhseCalculateInventory.ZeroQty.SetValue(ItemsNotOnInventory); // Control11: Items Not on Inventory.
        WhseCalculateInventory."Bin Content".SetFilter("Item No.", ItemNo);
        if Zone <> '' then
            WhseCalculateInventory."Bin Content".SetFilter("Zone Code", ZoneCode);
        if Bin <> '' then
            WhseCalculateInventory."Bin Content".SetFilter("Bin Code", BinCode);
        WhseCalculateInventory.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseCalculateInventoryRequestPageHandler2(var WhseCalculateInventory: TestRequestPage "Whse. Calculate Inventory")
    var
        ItemNo: Variant;
        LocationCode: Variant;
    begin
        LibraryVariableStorage.Dequeue(LocationCode);
        LibraryVariableStorage.Dequeue(ItemNo);
        WhseCalculateInventory.RegisteringDate.SetValue(WorkDate());
        WhseCalculateInventory.WhseDocumentNo.SetValue(LibraryUtility.GetGlobalNoSeriesCode());
        WhseCalculateInventory.ZeroQty.SetValue(false);
        WhseCalculateInventory."Bin Content".SetFilter("location Code", LocationCode);
        WhseCalculateInventory."Bin Content".SetFilter("Item No.", ItemNo);
        WhseCalculateInventory.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    begin
        ItemTrackingSummary.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure QuantityToCreateNewLotNoPageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        case LibraryVariableStorage.DequeueInteger() of
            AssignTracking::SerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();  // Open Enter Quantity to Create Page for Create Serial No or with Lot No.
            AssignTracking::SelectTrackingEntries:
                begin
                    ItemTrackingLines."Select Entries".Invoke();  // Open Page Item Tracking Summary for Select Line on Page handler ItemTrackingSummaryPageHandler.
                    ItemTrackingLines.OK().Invoke();
                end;
        end;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostProductionJournalHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesSerialNoPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesLotNoPageHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueDecimal());
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WhseItemTrackingLinesPageHandlerWithLotsAndExpirationDate(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    begin
        WhseItemTrackingLines."Lot No.".SetValue(LibraryVariableStorage.DequeueInteger());
        WhseItemTrackingLines."Package No.".SetValue(LibraryVariableStorage.DequeueInteger());
        WhseItemTrackingLines.Quantity.SetValue(LibraryVariableStorage.DequeueInteger());

        WhseItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SetSerialItemWithQtyToHandleTrackingPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    begin
        ItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        ItemTrackingLines."Quantity (Base)".SetValue(LibraryRandom.RandIntInRange(1, 1));
        ItemTrackingLines."Qty. to Handle (Base)".SetValue(LibraryRandom.RandIntInRange(1, 1));
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure WarehouseItemTrackingLinesHandler(var WhseItemTrackingLines: TestPage "Whse. Item Tracking Lines")
    var
    begin
        WhseItemTrackingLines."Serial No.".SetValue(LibraryVariableStorage.DequeueText());
        WhseItemTrackingLines.Quantity.SetValue(LibraryRandom.RandIntInRange(1, 1));
        WhseItemTrackingLines.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

