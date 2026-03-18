codeunit 137452 "Phys. Invt. Order Line TAB UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Physical Inventory] [Order Lne]
    end;

    var
        LibraryUTUtility: Codeunit "Library UT Utility";
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemReference: Codeunit "Library - Item Reference";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure OnRenamePhysInventoryOrderLineError()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate OnRename trigger of Table ID - 5005351 Physical Inventory Order Line.
        // Setup.
        PhysInvtOrderLine."Document No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderLine.Insert();

        // [WHEN] Rename Physical Inventory Order Line.
        asserterror PhysInvtOrderLine.Rename(LibraryUTUtility.GetNewCode(), 2);

        // [THEN] Verify error code, Physical Inventory Order Line cannot be renamed.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestQtyRecordedPhysInventoryOrderLineError()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [SCENARIO] validate TestQtyRecorded function of Table Physical Inventory Order Line.
        // Setup.
        PhysInvtOrderLine."Document No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine."Use Item Tracking" := true;
        PhysInvtOrderLine.Insert();

        PhysInvtRecordLine."Order No." := PhysInvtOrderLine."Document No.";
        PhysInvtRecordLine."Recording No." := 1;
        PhysInvtRecordLine."Order Line No." := PhysInvtOrderLine."Line No.";
        PhysInvtRecordLine."Quantity (Base)" := 1;
        PhysInvtRecordLine.Insert();

        // [WHEN] Run TestQtyRecorded function of Table Physical Inventory Order Line.
        asserterror PhysInvtOrderLine.TestQtyRecorded();

        // [THEN] Verify error code, Serial No. or a Lot No. must be specified in Physical Inventory Recording Line when Use Tracking Lines is set to TRUE.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure TestQtyRecordedPhysInvtOrderLineQtyError()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate TestQtyRecorded function of Table ID - 5005351  Phys. Inventory Order Line.
        // Setup.
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, LibraryUTUtility.GetNewCode());
        PhysInvtOrderLine."Qty. Recorded (Base)" := 1;
        PhysInvtOrderLine.Modify();

        // Exercise.
        asserterror PhysInvtOrderLine.TestQtyRecorded();

        // [THEN] Verify error code, The value of field Qty. Recorded (Base) and the sum of all Phys. Invt. Recording Line, field Quantity (Base), of the order line are different.
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('PhysInvtRecLinesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowPhysInvtRecordingLinesPhysInvtOrderLine()
    var
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate ShowPhysInvtRecordLines function of Table ID - 5005351  Phys. Inventory Order Line.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, LibraryUTUtility.GetNewCode());
        PhysInvtOrderLine."On Recording Lines" := true;
        PhysInvtOrderLine.Modify();

        PhysInvtRecordLine."Order No." := PhysInvtOrderLine."Document No.";
        PhysInvtRecordLine."Order Line No." := PhysInvtOrderLine."Line No.";
        PhysInvtRecordLine.Insert();

        // Exercise & verify: Invokes function ShowPhysInvtRecordLines on Table Phys. Inventory Order Line and verify correct entries created in PhysInvtRecLinesPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Document No.");  // Required inside PhysInvtRecLinesPageHandler.
        PhysInvtOrderLine.ShowPhysInvtRecordingLines();  // Invokes PhysInvtRecLinesPageHandler.
    end;

    [Test]
    [HandlerFunctions('ExpInvtOrderTrackingPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowExpectInvtOrderTrackingLinesPhysInvtOrderLine()
    var
        ExpInvtOrderTracking: Record "Exp. Invt. Order Tracking";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate ShowExpPhysInvtTrackings function of Table ID - 5005351  Phys. Inventory Order Line.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, LibraryUTUtility.GetNewCode());
        PhysInvtOrderLine."Qty. Exp. Calculated" := true;
        PhysInvtOrderLine.Modify();

        ExpInvtOrderTracking."Order No" := PhysInvtOrderLine."Document No.";
        ExpInvtOrderTracking."Order Line No." := PhysInvtOrderLine."Line No.";
        ExpInvtOrderTracking.Insert();

        // Exercise & verify: Invokes function ShowExpPhysInvtTracking on Table Phys. Inventory Order Line and verify correct entries created in ExpectPhysInvTrackListPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Document No.");  // Required inside ExpectPhysInvTrackListPageHandler.
        PhysInvtOrderLine.ShowExpectPhysInvtTrackLines();  // Invokes ExpectPhysInvTrackListPageHandler.
    end;

    [Test]
    [HandlerFunctions('PhysInventoryLedgerEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowPhysInvtLedgerEntriesPhysInvtOrderLine()
    var
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderHeaderNo: Code[20];
    begin
        // [SCENARIO] validate ShowPhysInvtLedgerEntries function of Table ID - 5005351  Phys. Inventory Order Line.
        // Setup.
        Initialize();
        PhysInvtOrderHeaderNo := CreatePhysInventoryOrderHeader();
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeaderNo);

        CreatePhysInventoryLedgerEntry(PhysInventoryLedgerEntry, PhysInvtOrderHeaderNo);
        PhysInventoryLedgerEntry."Item No." := PhysInvtOrderLine."Item No.";
        PhysInventoryLedgerEntry.Modify();

        // Exercise & verify: Invokes function ShowPhysInvtLedgerEntries on Table Phys. Inventory Order Line and verify correct entries created in PhysInventoryLedgerEntriesPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderHeaderNo);  // Required inside PhysInventoryLedgerEntriesPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");  // Required inside PhysInventoryLedgerEntriesPageHandler.
        PhysInvtOrderLine.ShowPhysInvtLedgerEntries();  // Invokes PhysInventoryLedgerEntriesPageHandler.
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EmptyLinePhysInvtOrderLine()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Function EmptyLine for Table 5005351 - Phys. Invt. Order Line.

        // Exercise and Verify: Verify EmptyLine Function return True value.
        Assert.IsTrue(PhysInvtOrderLine.EmptyLine(), 'Physical Inventory Order Line must empty.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure EmptyLinePhysInvtOrderLineForExistingLine()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Function EmptyLine for Table 5005351 - Phys. Invt. Order Line.
        // Setup.
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, LibraryUTUtility.GetNewCode());

        // Exercise and Verify: Verify EmptyLine Function return False Value.
        Assert.IsFalse(PhysInvtOrderLine.EmptyLine(), 'Physical Inventory Order Line must not be empty.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShortcutDim1CodeOnValidatePhysInvtOrderLine()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Trigger OnValidate of Shortcut Dimension 1 Code for Table 5005351 - Phys. Inventory Order Line.
        // Setup.
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, LibraryUTUtility.GetNewCode());

        // Exercise.
        PhysInvtOrderLine.Validate("Shortcut Dimension 1 Code", SelectDimensionValue(1));

        // [THEN] Verify Dimension Set ID.
        PhysInvtOrderLine.TestField("Dimension Set ID");
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShortcutDim2CodeOnValidatePhysInvtOrderLine()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate Trigger OnValidate of Shortcut Dimension 2 Code for Table 5005351 - Phys. Inventory Order Line.
        // Setup.
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, LibraryUTUtility.GetNewCode());

        // Exercise.
        PhysInvtOrderLine.Validate("Shortcut Dimension 2 Code", SelectDimensionValue(2));

        // [THEN] Verify Dimension Set ID.
        PhysInvtOrderLine.TestField("Dimension Set ID");
    end;

    [Test]
    [HandlerFunctions('BinContentsListPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowBinContentItemPhysInvtOrderLine()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        BinContent: Record "Bin Content";
    begin
        // [SCENARIO] validate function ShowBinContentItem for Table 5005351 - Phys. Inventory Order Line.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, LibraryUTUtility.GetNewCode());

        BinContent."Item No." := PhysInvtOrderLine."Item No.";
        BinContent.Insert();

        // Exercise & verify: Invokes function ShowBinContentItem on Table Phys. Inventory Order Line and verify correct entries created in BinContentsListPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");  // Required inside BinContentsListPageHandler.
        PhysInvtOrderLine.ShowBinContentItem();  // Invokes BinContentsListPageHandler.
    end;

    [Test]
    [HandlerFunctions('BinContentsListForBinPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowBinContentBinPhysInvtOrderLine()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        BinContent: Record "Bin Content";
        Location: Record Location;
    begin
        // [SCENARIO] validate function ShowBinContentBin for Table 5005351 - Phys. Inventory Order Line.
        // Setup.
        Initialize();
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, LibraryUTUtility.GetNewCode());
        Location.Init();
        Location.Code := LibraryUTUtility.GetNewCode10();
        if Location.Insert() then;
        PhysInvtOrderLine."Location Code" := Location.Code;
        PhysInvtOrderLine."Bin Code" := LibraryUTUtility.GetNewCode();
        PhysInvtOrderLine.Modify();

        BinContent."Item No." := PhysInvtOrderLine."Item No.";
        BinContent."Location Code" := PhysInvtOrderLine."Location Code";
        BinContent."Bin Code" := PhysInvtOrderLine."Bin Code";
        BinContent.Insert();

        // Exercise & verify: Invokes function ShowBinContentBin on Table Phys. Inventory Order Line and verify correct entries created in BinContentsListForBinPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Location Code");  // Required inside BinContentsListForBinPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Bin Code");  // Required inside BinContentsListForBinPageHandler.
        LibraryVariableStorage.Enqueue(PhysInvtOrderLine."Item No.");  // Required inside BinContentsListForBinPageHandler.
        PhysInvtOrderLine.ShowBinContentBin();
    end;

    [Test]
    [HandlerFunctions('EditDimensionSetEntriesPageHandler')]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure ShowDimensionsPhysInvtOrderLine()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [SCENARIO] validate function ShowDimensions for Table 5005351 - Phys. Inventory Order Line.
        // Setup.
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, LibraryUTUtility.GetNewCode());

        // Exercise & verify: Invokes ShowDimensions on Table Phys. Inventory Order Line. Verify Dimension Set Entries Page Open. Added Page Handler EditDimensionSetEntriesPageHandler.
        PhysInvtOrderLine.ShowDimensions();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    [Scope('OnPrem')]
    procedure UseTrackingLinesOnValidatePhysInvtOrderLine()
    var
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtOrderHeaderNo: Code[20];
    begin
        // [SCENARIO] validate Trigger OnValidate of Use Tracking Lines for Table 5005351 - Phys. Inventory Order Line.
        // Setup.
        PhysInvtOrderHeaderNo := CreatePhysInventoryOrderHeader();
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, PhysInvtOrderHeaderNo);
        PhysInvtOrderLine."Qty. Expected (Base)" := 1;
        PhysInvtOrderLine."Qty. Exp. Calculated" := true;
        PhysInvtOrderLine.Modify();

        // Exercise.
        PhysInvtOrderLine.Validate("Use Item Tracking", true);

        // [THEN] Verify Qty. Expected (Base) and Qty. Exp. Calculated are reset to the default value.
        PhysInvtOrderLine.TestField("Qty. Expected (Base)", 0);
        PhysInvtOrderLine.TestField("Qty. Exp. Calculated", false);
    end;


    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemReferenceList1ItemReferenceModalPageHandler')]
    procedure ItemReferenceOnLookupPhysInvtOrderLine()
    var
        ItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInventoryOrderSubf: TestPage "Physical Inventory Order Subf.";
    begin
        // [GIVEN] Physical Inventory Order document 
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, CreatePhysInventoryOrderHeader());

        // [GIVEN] Different item references exist
        CreateDifferentItemReferencesWithSameReferenceNoAndUOM(ItemReference);

        // [WHEN] Lookup references
        PhysInventoryOrderSubf.OpenEdit();
        PhysInventoryOrderSubf.GoToRecord(PhysInvtOrderLine);
        PhysInventoryOrderSubf."Item Reference No.".Lookup();
        PhysInventoryOrderSubf.Close();

        // [THEN] Info from item reference is copied
        TestPhysInvtOrderLineReferenceFields(PhysInvtOrderLine, ItemReference);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceBarCodeOnValidatePhysInvtOrderLineNonBaseUoM()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [GIVEN] Physical Inventory Order document 
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, CreatePhysInventoryOrderHeader());

        // [GIVEN] Item Reference for Item exists with non-base UoM code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 2);
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", '', ItemUnitOfMeasure.Code, "Item Reference Type"::"Bar Code", '', LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), Database::"Item Reference"));

        ItemReference.Validate("Unit of Measure", ItemUnitOfMeasure.Code);
        ItemReference.Modify(true);

        // [WHEN] Validate item reference no using existing refernce no that has non-base unit of measure
        asserterror PhysInvtOrderLine.Validate("Item Reference No.", ItemReference."Reference No.");

        // [THEN] Verify error
        Assert.ExpectedError(ItemReference.FieldCaption("Unit of Measure") + ' must not be ' + ItemReference."Unit of Measure" + ' in ' + ItemReference.TableCaption());
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemReferenceList2ItemReferencesModalPageHandler')]
    procedure ItemReferenceOnValidatePhysInvtRecordLine()
    var
        ItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtRecordingSubform: TestPage "Phys. Invt. Recording Subform";
    begin
        // [GIVEN] Physical Inventory Recording line
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, CreatePhysInventoryOrderHeader());
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderLine."Document No.");
        LibraryInventory.CreatePhysInvtRecordLine(PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", 1);

        // [GIVEN] Different item references exist
        CreateDifferentItemReferencesWithSameReferenceNo(ItemReference);

        // [WHEN] Validate item reference no using existing refernce no
        PhysInvtRecordingSubform.OpenEdit();
        PhysInvtRecordingSubform.GoToRecord(PhysInvtRecordLine);
        PhysInvtRecordingSubform."Item Reference No.".Value(ItemReference."Reference No.");
        PhysInvtRecordingSubform.Close();

        // [THEN] Info from item reference is copied
        TestPhysInvtRecordLineReferenceFields(PhysInvtRecordLine, ItemReference);
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('ItemReferenceList1ItemReferenceModalPageHandler')]
    procedure ItemReferenceOnLookupPhysInvtRecordLine()
    var
        ItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
        PhysInvtRecordingSubform: TestPage "Phys. Invt. Recording Subform";
    begin
        // [GIVEN] Physical Inventory Recording line
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, CreatePhysInventoryOrderHeader());
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderLine."Document No.");
        LibraryInventory.CreatePhysInvtRecordLine(PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", 1);

        // [GIVEN] Different item references exist
        CreateDifferentItemReferencesWithSameReferenceNo(ItemReference);

        // [WHEN] Lookup references
        PhysInvtRecordingSubform.OpenEdit();
        PhysInvtRecordingSubform.GoToRecord(PhysInvtRecordLine);
        PhysInvtRecordingSubform."Item Reference No.".Lookup();
        PhysInvtRecordingSubform.Close();

        // [THEN] Info from item reference is copied
        TestPhysInvtRecordLineReferenceFields(PhysInvtRecordLine, ItemReference);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceBarCodeOnValidatePhysInvtRecordLineNonBaseUoM()
    var
        Item: Record Item;
        ItemReference: Record "Item Reference";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
        PhysInvtRecordHeader: Record "Phys. Invt. Record Header";
        PhysInvtRecordLine: Record "Phys. Invt. Record Line";
    begin
        // [GIVEN] Physical Inventory Recording line
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, CreatePhysInventoryOrderHeader());
        LibraryInventory.CreatePhysInvtRecordHeader(PhysInvtRecordHeader, PhysInvtOrderLine."Document No.");
        LibraryInventory.CreatePhysInvtRecordLine(PhysInvtRecordLine, PhysInvtOrderLine, PhysInvtRecordHeader."Recording No.", 1);

        // [GIVEN] Item Reference for Item exists with non-base UoM code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 2);
        LibraryItemReference.CreateItemReference(ItemReference, Item."No.", '', ItemUnitOfMeasure.Code, "Item Reference Type"::"Bar Code", '', LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), Database::"Item Reference"));

        ItemReference.Validate("Unit of Measure", ItemUnitOfMeasure.Code);
        ItemReference.Modify(true);

        // [WHEN] Validate item reference no using existing refernce no that has non-base unit of measure
        PhysInvtRecordLine.Validate("Item Reference No.", ItemReference."Reference No.");
        PhysInvtRecordLine.Modify();

        // [THEN] Unit of measure is applied in the line
        Assert.AreEqual(ItemReference."Unit of Measure", PhysInvtRecordLine."Unit of Measure Code", PhysInvtRecordLine.FieldCaption("Unit of Measure Code"));
        Assert.AreEqual(ItemUnitOfMeasure."Qty. per Unit of Measure", PhysInvtRecordLine."Qty. per Unit of Measure", PhysInvtRecordLine.FieldCaption("Qty. per Unit of Measure"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemReferenceOnValidatePhysInvtOrderLineWithNonBaseUOM()
    var
        ItemReference: Record "Item Reference";
        PhysInvtOrderLine: Record "Phys. Invt. Order Line";
    begin
        // [GIVEN] Physical Inventory Order document 
        CreatePhysInventoryOrderLine(PhysInvtOrderLine, CreatePhysInventoryOrderHeader());

        // [GIVEN] Different item references exist
        CreateDifferentItemReferencesWithSameReferenceNo(ItemReference);

        // [WHEN] Validate item reference no using existing refernce no
        asserterror PhysInvtOrderLine.Validate("Item Reference No.", ItemReference."Reference No.");
        Assert.ExpectedError('Unit of Measure must not be');
    end;

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
    end;

    local procedure CreatePhysInventoryOrderHeader(): Code[20]
    var
        PhysInvtOrderHeader: Record "Phys. Invt. Order Header";
    begin
        PhysInvtOrderHeader."No." := LibraryUTUtility.GetNewCode();
        PhysInvtOrderHeader."Posting Date" := WorkDate();
        PhysInvtOrderHeader.Insert();
        exit(PhysInvtOrderHeader."No.");
    end;

    local procedure CreatePhysInventoryOrderLine(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; DocumentNo: Code[20])
    var
        Item: Record Item;
    begin
        Item."No." := LibraryUTUtility.GetNewCode();
        Item.Insert();

        PhysInvtOrderLine."Document No." := DocumentNo;
        PhysInvtOrderLine."Line No." := 1;
        PhysInvtOrderLine."Item No." := Item."No.";
        PhysInvtOrderLine.Insert();
    end;

    local procedure CreatePhysInventoryLedgerEntry(var PhysInventoryLedgerEntry2: Record "Phys. Inventory Ledger Entry"; DocumentNo: Code[20])
    var
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
    begin
        PhysInventoryLedgerEntry.FindLast();
        PhysInventoryLedgerEntry2."Entry No." := PhysInventoryLedgerEntry."Entry No." + 1;
        PhysInventoryLedgerEntry2."Document No." := DocumentNo;
        PhysInventoryLedgerEntry2."Posting Date" := WorkDate();
        PhysInventoryLedgerEntry2.Insert();
    end;

    local procedure SelectDimensionValue(GlobalDimensionNo: Integer): Code[20]
    var
        DimensionValue: Record "Dimension Value";
    begin
        DimensionValue.SetRange("Global Dimension No.", GlobalDimensionNo);
        DimensionValue.SetRange("Dimension Value Type", DimensionValue."Dimension Value Type"::Standard);
        DimensionValue.FindFirst();
        exit(DimensionValue.Code);
    end;

    local procedure CreateDifferentItemReferencesWithSameReferenceNo(var FirstItemReference: Record "Item Reference")
    var
        Item: Record Item;
        AdditionalItemReference: Record "Item Reference";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
    begin
        FirstItemReference.DeleteAll();
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 10);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryItemReference.CreateItemReference(FirstItemReference, Item."No.", "Item Reference Type"::" ", '');
        FirstItemReference.Rename(FirstItemReference."Item No.", ItemVariant.Code, ItemUnitOfMeasure.Code, FirstItemReference."Reference Type", FirstItemReference."Reference Type No.", FirstItemReference."Reference No.");
        FirstItemReference.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(FirstItemReference.Description)));
        FirstItemReference.Validate("Description 2", LibraryUtility.GenerateRandomText(MaxStrLen(FirstItemReference."Description 2")));
        FirstItemReference.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryItemReference.CreateItemReferenceWithNo(AdditionalItemReference, FirstItemReference."Reference No.", Item."No.", FirstItemReference."Reference Type"::"Bar Code", '');
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryItemReference.CreateItemReferenceWithNo(AdditionalItemReference, FirstItemReference."Reference No.", Item."No.", FirstItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryItemReference.CreateItemReferenceWithNo(AdditionalItemReference, FirstItemReference."Reference No.", Item."No.", FirstItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());
    end;

    local procedure CreateDifferentItemReferencesWithSameReferenceNoandUOM(var FirstItemReference: Record "Item Reference")
    var
        Item: Record Item;
        AdditionalItemReference: Record "Item Reference";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
    begin
        FirstItemReference.DeleteAll();
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        // Create specific UoM to be used in all references
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 10);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        // First reference
        LibraryItemReference.CreateItemReference(FirstItemReference, Item."No.", "Item Reference Type"::" ", '');
        // Rename to have same UoM and new item variant 
        FirstItemReference.Rename(FirstItemReference."Item No.", ItemVariant.Code, FirstItemReference."Unit of Measure", FirstItemReference."Reference Type", FirstItemReference."Reference Type No.", FirstItemReference."Reference No.");
        FirstItemReference.Validate(Description, LibraryUtility.GenerateRandomText(MaxStrLen(FirstItemReference.Description)));
        FirstItemReference.Validate("Description 2", LibraryUtility.GenerateRandomText(MaxStrLen(FirstItemReference."Description 2")));
        FirstItemReference.Modify(true);

        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        // Additional references 
        LibraryItemReference.CreateItemReferenceWithNo(AdditionalItemReference, FirstItemReference."Reference No.", Item."No.", FirstItemReference."Reference Type"::"Bar Code", '');
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryItemReference.CreateItemReferenceWithNo(AdditionalItemReference, FirstItemReference."Reference No.", Item."No.", FirstItemReference."Reference Type"::Customer, LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryItemReference.CreateItemReferenceWithNo(AdditionalItemReference, FirstItemReference."Reference No.", Item."No.", FirstItemReference."Reference Type"::Vendor, LibraryPurchase.CreateVendorNo());
    end;

    local procedure TestPhysInvtOrderLineReferenceFields(var PhysInvtOrderLine: Record "Phys. Invt. Order Line"; ItemReference: Record "Item Reference")
    begin
        PhysInvtOrderLine.SetRecFilter();
        PhysInvtOrderLine.FindFirst();
        PhysInvtOrderLine.TestField("Item No.", ItemReference."Item No.");
        PhysInvtOrderLine.TestField("Base Unit of Measure Code", ItemReference."Unit of Measure");
        PhysInvtOrderLine.TestField("Variant Code", ItemReference."Variant Code");
        PhysInvtOrderLine.TestField("Description", ItemReference."Description");
        PhysInvtOrderLine.TestField("Description 2", ItemReference."Description 2");
        PhysInvtOrderLine.TestField("Item Reference Type", ItemReference."Reference Type");
        PhysInvtOrderLine.TestField("Item Reference Type No.", ItemReference."Reference Type No.");
        PhysInvtOrderLine.TestField("Item Reference Unit of Measure", ItemReference."Unit of Measure");
    end;

    local procedure TestPhysInvtRecordLineReferenceFields(var PhysInvtRecordLine: Record "Phys. Invt. Record Line"; ItemReference: Record "Item Reference")
    begin
        PhysInvtRecordLine.SetRecFilter();
        PhysInvtRecordLine.FindFirst();
        PhysInvtRecordLine.TestField("Item No.", ItemReference."Item No.");
        PhysInvtRecordLine.TestField("Unit of Measure Code", ItemReference."Unit of Measure");
        PhysInvtRecordLine.TestField("Variant Code", ItemReference."Variant Code");
        PhysInvtRecordLine.TestField("Description 2", ItemReference."Description 2");
        PhysInvtRecordLine.TestField("Description", ItemReference."Description");
        PhysInvtRecordLine.TestField("Description 2", ItemReference."Description 2");
        PhysInvtRecordLine.TestField("Item Reference Type", ItemReference."Reference Type");
        PhysInvtRecordLine.TestField("Item Reference Type No.", ItemReference."Reference Type No.");
        PhysInvtRecordLine.TestField("Item Reference Unit of Measure", ItemReference."Unit of Measure");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PhysInvtRecLinesPageHandler(var PhysInvtRecordingLines: TestPage "Phys. Invt. Recording Lines")
    var
        OrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(OrderNo);
        PhysInvtRecordingLines."Order No.".AssertEquals(OrderNo);
        PhysInvtRecordingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ExpInvtOrderTrackingPageHandler(var ExpInvtOrderTracking: TestPage "Exp. Invt. Order Tracking")
    var
        OrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(OrderNo);
        ExpInvtOrderTracking."Order No".AssertEquals(OrderNo);
        ExpInvtOrderTracking."Order Line No.".AssertEquals(1);
        ExpInvtOrderTracking.OK().Invoke();
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
        PhysInventoryLedgerEntries."Posting Date".AssertEquals(WorkDate());
        PhysInventoryLedgerEntries."Item No.".AssertEquals(ItemNo);
        PhysInventoryLedgerEntries.OK().Invoke();
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
    procedure EditDimensionSetEntriesPageHandler(var EditDimensionSetEntries: TestPage "Edit Dimension Set Entries")
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemReferenceList1ItemReferenceModalPageHandler(var ItemReferenceList: TestPage "Item Reference List")
    var
        ItemNo: Code[20];
    begin
        ItemNo := LibraryVariableStorage.DequeueText();
        ItemReferenceListContains(ItemReferenceList, ItemNo);
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());

        ItemReferenceList.Filter.SetFilter("Item No.", ItemNo);
        ItemReferenceList.First(); // Return the item reference for the first item
        ItemReferenceList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemReferenceList2ItemReferencesModalPageHandler(var ItemReferenceList: TestPage "Item Reference List")
    var
        ItemNo: Code[20];
    begin
        ItemNo := LibraryVariableStorage.DequeueText();
        ItemReferenceListContains(ItemReferenceList, ItemNo);
        ItemReferenceListContains(ItemReferenceList, LibraryVariableStorage.DequeueText());
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());
        ItemReferenceListNotContains(ItemReferenceList, LibraryVariableStorage.DequeueText());

        ItemReferenceList.Filter.SetFilter("Item No.", ItemNo);
        ItemReferenceList.First(); // Return the item reference for the first item
        ItemReferenceList.OK().Invoke();
    end;

    local procedure ItemReferenceListContains(var ItemReferenceList: TestPage "Item Reference List"; ItemNo: Code[20])
    begin
        ItemReferenceList.Filter.SetFilter("Item No.", ItemNo);
        Assert.IsTrue(ItemReferenceList.First(), 'Item Reference List does not contain entry that should be visible');
    end;

    local procedure ItemReferenceListNotContains(var ItemReferenceList: TestPage "Item Reference List"; ItemNo: Code[20])
    begin
        ItemReferenceList.Filter.SetFilter("Item No.", ItemNo);
        Assert.IsFalse(ItemReferenceList.First(), 'Item Reference List contains entry that should not be visible');
    end;
}

