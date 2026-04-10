codeunit 137220 "SCM CreateWarehouseLocation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Warehouse] [Location] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        IsInitialized: Boolean;
        UnexpectedMessage: Label 'Unexpected : "%1". Expected: "%2"';
        ErrEnterLocationCode: Label 'Enter a location code.';
        ErrEnterAdjCode: Label 'Enter an adjustment bin code.';
        ErrNoActiveKey: Label 'The Item Ledger Entry table does not have an active key that starts with the following field or fields: Item No.,Location Code,Open,Variant Code,Unit of Measure Code,Lot No.,Serial No..';
        ErrNothingToConvert: Label 'There is nothing to convert for Location Code ''%1''';
        ErrBinDoesNotExist: Label 'The Bin does not exist';

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM CreateWarehouseLocation");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM CreateWarehouseLocation");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        // ItemJournalSetup(ItemJournalTemplate, ItemJournalBatch);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM CreateWarehouseLocation");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756EmptyLocEmptyBin()
    begin
        Initialize();

        ConvertLocationWithErrorTest('', '', ErrEnterLocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756EmptyLocNotExistBin()
    var
        Bin: Record Bin;
        NotExistingBinCode: Code[20];
    begin
        Initialize();
        NotExistingBinCode := CopyStr(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code)));

        ConvertLocationWithErrorTest('', NotExistingBinCode, ErrEnterLocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756EmptyLocExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
    begin
        Initialize();
        CreateLocationBinItem(Location, Bin);

        ConvertLocationWithErrorTest('', Bin.Code, ErrEnterLocationCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756ExistLocEmptyBin()
    var
        Bin: Record Bin;
        Location: Record Location;
    begin
        Initialize();
        CreateLocationBinItem(Location, Bin);

        ConvertLocationWithErrorTest(Location.Code, '', ErrEnterAdjCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756ExistLocNotExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
        ItemLedgEntry: Record "Item Ledger Entry";
        NotExistingBinCode: Code[20];
    begin
        Initialize();
        NotExistingBinCode := CopyStr(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code)));
        CreateLocationBinItem(Location, Bin);

        ItemLedgEntry.FindFirst();
        if ItemLedgEntry.SetCurrentKey("Item No.", "Location Code", Open, "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.") then
            ConvertLocationWithErrorTest(Location.Code, NotExistingBinCode, ErrBinDoesNotExist)
        else
            ConvertLocationWithErrorTest(Location.Code, NotExistingBinCode, ErrNoActiveKey);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756ExistLocExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
        ItemLedgEntry: Record "Item Ledger Entry";
        CreateWarehouseLocation: Report "Create Warehouse Location";
    begin
        Initialize();
        CreateLocationBinItem(Location, Bin);

        ItemLedgEntry.FindFirst();
        if ItemLedgEntry.SetCurrentKey("Item No.", "Location Code", Open, "Variant Code", "Unit of Measure Code", "Lot No.", "Serial No.") then begin
            Clear(CreateWarehouseLocation);
            CreateWarehouseLocation.SetHideValidationDialog(true);
            CreateWarehouseLocation.InitializeRequest(Location.Code, Bin.Code);

            CreateWarehouseLocation.UseRequestPage(false);
            CreateWarehouseLocation.RunModal();

            Commit();  // commit is required
            Location.Get(Location.Code);
            Assert.AreEqual(true, Location."Require Receive", 'Incorrect require receive flag');
            Assert.AreEqual(true, Location."Require Shipment", 'Incorrect require receive shipment flag');
            Assert.AreEqual(true, Location."Require Put-away", 'Incorrect require put-away flag');
            Assert.AreEqual(false, Location."Use Put-away Worksheet", 'Incorrect use put-away worksheet flag');
            Assert.AreEqual(true, Location."Require Pick", 'Incorrect require pick flag');
            Assert.AreEqual(true, Location."Bin Mandatory", 'Incorrect Bin Mandatory flag');
            Assert.AreEqual(true, Location."Directed Put-away and Pick", 'Incorrect Directed Put-away and Pick flag');
        end else
            ConvertLocationWithErrorTest(Location.Code, Bin.Code, ErrNoActiveKey);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756NonExistLocEmptyBin()
    var
        Location: Record Location;
        NotExistingLocationCode: Code[10];
    begin
        Initialize();
        NotExistingLocationCode := CopyStr(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location),
            1, LibraryUtility.GetFieldLength(DATABASE::Location, Location.FieldNo(Code)));

        ConvertLocationWithErrorTest(NotExistingLocationCode, '', ErrEnterAdjCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756NonExistLocNonExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
        NotExistingBinCode: Code[20];
        NotExistingLocationCode: Code[10];
    begin
        Initialize();
        NotExistingBinCode := CopyStr(LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code)));

        NotExistingLocationCode := CopyStr(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location),
            1, LibraryUtility.GetFieldLength(DATABASE::Location, Location.FieldNo(Code)));

        ConvertLocationWithErrorTest(NotExistingLocationCode, NotExistingBinCode, StrSubstNo(ErrNothingToConvert, NotExistingLocationCode));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RP5756NonExistLocExistBin()
    var
        Bin: Record Bin;
        Location: Record Location;
        NotExistingLocationCode: Code[10];
    begin
        Initialize();
        NotExistingLocationCode := CopyStr(LibraryUtility.GenerateRandomCode(Location.FieldNo(Code), DATABASE::Location),
            1, LibraryUtility.GetFieldLength(DATABASE::Location, Location.FieldNo(Code)));

        CreateLocationBinItem(Location, Bin);

        ConvertLocationWithErrorTest(NotExistingLocationCode, Bin.Code, StrSubstNo(ErrNothingToConvert, NotExistingLocationCode));
    end;

    [Test]
    procedure CreateWarehouseLocation_VerifyWarehouseEntries()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        WarehouseEntry: Record "Warehouse Entry";
        PostingCombinations: Dictionary of [Text, Decimal];
        Combination: Text;
        LotNo: Code[50];
        Qty: Decimal;
        i, j, k, l : Integer;
    begin
        // [FEATURE] [Create Warehouse Location]
        // [SCENARIO 500812] Verify warehouse entries are created when a location is converted to a warehouse location.
        Initialize();

        // [GIVEN] Location and bin.
        CreateLocationBin(Location, Bin);

        // [GIVEN] 3 items, 3 variants for each item, 3 lots for each variant, 3 journal lines for each lot.
        for i := 1 to 3 do begin
            LibraryItemTracking.CreateLotItem(Item);

            for j := 1 to 3 do begin
                LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

                for k := 1 to 3 do begin
                    LotNo := LibraryUtility.GenerateGUID();
                    Combination := Item."No." + ',' + ItemVariant.Code + ',' + LotNo;
                    PostingCombinations.Add(Combination, 0);

                    for l := 1 to 3 do begin
                        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', LibraryRandom.RandInt(100));
                        ItemJournalLine.Validate("Variant Code", ItemVariant.Code);
                        ItemJournalLine.Modify(true);
                        LibraryItemTracking.CreateItemJournalLineItemTracking(ReservationEntry, ItemJournalLine, '', LotNo, ItemJournalLine.Quantity);
                        Qty := PostingCombinations.Get(Combination);
                        PostingCombinations.Set(Combination, Qty + ItemJournalLine.Quantity);
                    end;
                end;
            end;
        end;
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Convert the location to warehouse location.
        ConvertToWarehouseLocation(Location.Code, Bin.Code);

        // [THEN] Check that warehouse entries match each item's inventory by location, variant, and lot.
        foreach Combination in PostingCombinations.Keys() do begin
            Item.Get(Combination.Split(',').Get(1));
            Item.SetFilter("Variant Filter", Combination.Split(',').Get(2));
            Item.SetFilter("Lot No. Filter", Combination.Split(',').Get(3));
            Item.CalcFields(Inventory);

            WarehouseEntry.SetRange("Item No.", Item."No.");
            WarehouseEntry.SetFilter("Variant Code", Item.GetFilter("Variant Filter"));
            WarehouseEntry.SetFilter("Lot No.", Item.GetFilter("Lot No. Filter"));
            WarehouseEntry.CalcSums(Quantity);

            Item.TestField(Inventory, WarehouseEntry.Quantity);
        end;
    end;

    [Test]
    procedure CreateWarehouseLocation_UnitsOfMeasure()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ItemJournalLine: Record "Item Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Create Warehouse Location] [Unit of Measure]
        // [SCENARIO 500812] Create Warehouse Location creates warehouse entries with consideration of units of measure.
        Initialize();

        // [GIVEN] Location and bin.
        CreateLocationBin(Location, Bin);

        // [GIVEN] Item with 2 units of measure - 'PCS' and 'BOX'. 1 'BOX' = 10 'PCS'.
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 10);

        // [GIVEN] Item journal line for 50 'PCS'.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', 50);

        // [GIVEN] Item journal line for 5 'BOX'.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', 5);
        ItemJournalLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ItemJournalLine.Modify(true);

        // [GIVEN] Post both journal lines.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Convert the location to warehouse location.
        ConvertToWarehouseLocation(Location.Code, Bin.Code);

        // [THEN] Warehouse entries are created with correct quantities in both units of measure.
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.SetRange("Unit of Measure Code", Item."Base Unit of Measure");
        WarehouseEntry.CalcSums(Quantity);
        WarehouseEntry.TestField(Quantity, 50);

        WarehouseEntry.SetRange("Unit of Measure Code", ItemUnitOfMeasure.Code);
        WarehouseEntry.CalcSums(Quantity);
        WarehouseEntry.TestField(Quantity, 5);

        WarehouseEntry.SetRange("Unit of Measure Code");
        WarehouseEntry.CalcSums("Qty. (Base)");
        WarehouseEntry.TestField("Qty. (Base)", 100);
    end;

    [Test]
    procedure CreateWarehouseLocation_ErrorOnNegativeInventory()
    var
        Location: Record Location;
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Create Warehouse Location]
        // [SCENARIO 500812] Error is shown when converting location to warehouse location if at least one item has negative inventory.
        Initialize();

        // [GIVEN] Location and bin.
        CreateLocationBin(Location, Bin);

        // [GIVEN] Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Post item journal line for -10 qty.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', -10);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [WHEN] Convert the location to warehouse location.
        ConvertLocationWithErrorTest(Location.Code, Bin.Code, Format(Item."No."));

        // [THEN] Error is shown.

        // [THEN] After you make the inventory positive, the location can be converted successfully.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", Location.Code, '', 15);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        ConvertToWarehouseLocation(Location.Code, Bin.Code);
        WarehouseEntry.SetRange("Item No.", Item."No.");
        WarehouseEntry.CalcSums(Quantity);
        WarehouseEntry.TestField(Quantity, 5);
    end;

    local procedure ConvertToWarehouseLocation(LocationCode: Code[10]; BinCode: Code[20])
    var
        CreateWarehouseLocation: Report "Create Warehouse Location";
    begin
        CreateWarehouseLocation.SetHideValidationDialog(true);
        CreateWarehouseLocation.InitializeRequest(LocationCode, BinCode);
        CreateWarehouseLocation.UseRequestPage(false);
        Commit();
        CreateWarehouseLocation.RunModal();
    end;

    local procedure ConvertLocationWithErrorTest(LocationCode: Code[10]; BinCode: Code[20]; ExpectedErrorMessage: Text[1024])
    var
        CreateWarehouseLocation: Report "Create Warehouse Location";
    begin
        Clear(CreateWarehouseLocation);
        CreateWarehouseLocation.SetHideValidationDialog(true);
        CreateWarehouseLocation.InitializeRequest(LocationCode, BinCode);

        CreateWarehouseLocation.UseRequestPage(false);
        Commit();
        asserterror CreateWarehouseLocation.RunModal();

        if ExpectedErrorMessage = ErrBinDoesNotExist then
            Assert.ExpectedErrorCannotFind(Database::Bin);

        if StrPos(GetLastErrorText, ExpectedErrorMessage) = 0 then
            Assert.Fail(StrSubstNo(UnexpectedMessage, GetLastErrorText, ExpectedErrorMessage));
        ClearLastError();
        Clear(CreateWarehouseLocation);
    end;

    local procedure CreateLocationBin(var Location: Record Location; var Bin: Record Bin)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, false);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin),
            1, LibraryUtility.GetFieldLength(DATABASE::Bin, Bin.FieldNo(Code))), '', '');
    end;

    local procedure CreateLocationBinItem(var Location: Record Location; var Bin: Record Bin)
    var
        Item: Record Item;
    begin
        CreateLocationBin(Location, Bin);
        LibraryInventory.CreateItem(Item);
        AddInventoryNonDirectLocation(Item, Location.Code);
    end;

    local procedure AddInventoryNonDirectLocation(Item: Record Item; LocationCode: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationCode, '', LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;
}

