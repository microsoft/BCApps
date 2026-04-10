codeunit 138028 "O365 Adjust Inventory"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Inventory] [SMB]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        UnexpectedFilterErr: Label 'Unexpected filter';
        WrongDrillDownValueErr: Label 'Wrong field value on the page';

    [Test]
    [HandlerFunctions('SimpleInvModalPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSimpleInvPageFromList()
    var
        Item: Record Item;
        ItemList: TestPage "Item List";
    begin
        Initialize();

        CreateNumberOfItem(Item);

        ItemList.OpenEdit();
        ItemList.GotoRecord(Item);

        LibraryVariableStorage.Enqueue(Item."No.");

        ItemList.AdjustInventory.Invoke();
        ItemList.Close();
    end;

    [Test]
    [HandlerFunctions('SimpleInvModalPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSimpleInvPageFromCard()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        CreateNumberOfItem(Item);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        LibraryVariableStorage.Enqueue(Item."No.");

        ItemCard.AdjustInventory.Invoke();
        ItemCard.Close();
    end;

    [Test]
    [HandlerFunctions('SimpleInvModalPageHandler')]
    [Scope('OnPrem')]
    procedure OpenSimpleInvPageFromCardViaAssistEdit()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        CreateNumberOfItem(Item);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        LibraryVariableStorage.Enqueue(Item."No.");

        ItemCard.Inventory.AssistEdit();
        ItemCard.Close();
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure PositiveAdjmt()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
    begin
        Initialize();

        CreateNumberOfItem(Item);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := LibraryRandom.RandDecInRange(20, 30, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandlerForLocation')]
    [Scope('OnPrem')]
    procedure PositiveAdjmtForOneLocation()
    var
        Item: Record Item;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
        LocationCode: Code[10];
    begin
        Initialize();
        LibraryApplicationArea.EnableLocationsSetup();

        CreateAndPostItem(Item, LocationCode);

        NewInventory := LibraryRandom.RandDecInRange(10, 20, 2);
        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        LibraryVariableStorage.Enqueue(NewInventory);
        LibraryVariableStorage.Enqueue(LocationCode);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventoryForLocation(Item, NewInventory, LocationCode);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandlerForLocation')]
    [Scope('OnPrem')]
    procedure NegativeAdjmtForOneLocation()
    var
        Item: Record Item;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
        LocationCode: Code[10];
    begin
        Initialize();
        LibraryApplicationArea.EnableLocationsSetup();

        CreateAndPostItem(Item, LocationCode);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := -LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        LibraryVariableStorage.Enqueue(LocationCode);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventoryForLocation(Item, NewInventory, LocationCode);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandlerForSeveralLocations')]
    [Scope('OnPrem')]
    procedure AdjustmentForSeveralLocations()
    var
        Item: Record Item;
        LibraryApplicationArea: Codeunit "Library - Application Area";
        ItemCard: TestPage "Item Card";
        SecondNewInventory: Decimal;
        FirstNewInventory: Decimal;
        FirstOldInventory: Decimal;
        SecondOldInventory: Decimal;
        FirstLocationCode: Code[10];
        SecondLocationCode: Code[10];
    begin
        Initialize();
        LibraryApplicationArea.EnableLocationsSetup();

        CreateNumberOfItem(Item);
        FirstLocationCode := GetLocation();
        FirstOldInventory := LibraryRandom.RandDecInRange(0, 10, 2);
        CreateAndPostItemJournalLine(Item."No.", FirstLocationCode, FirstOldInventory);

        SecondLocationCode := GetLocation();
        SecondOldInventory := LibraryRandom.RandDecInRange(40, 50, 2);
        CreateAndPostItemJournalLine(Item."No.", SecondLocationCode, SecondOldInventory);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        FirstNewInventory := FirstOldInventory + LibraryRandom.RandDecInRange(20, 30, 2);
        SecondNewInventory := SecondOldInventory - LibraryRandom.RandDecInRange(20, 30, 2);
        LibraryVariableStorage.Enqueue(FirstNewInventory);
        LibraryVariableStorage.Enqueue(FirstLocationCode);
        LibraryVariableStorage.Enqueue(SecondNewInventory);
        LibraryVariableStorage.Enqueue(SecondLocationCode);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventoryForLocation(Item, FirstNewInventory, FirstLocationCode);
        ValidateNewInventoryForLocation(Item, SecondNewInventory, SecondLocationCode);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeAdjmt()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
    begin
        Initialize();

        CreateNumberOfItem(Item);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := -LibraryRandom.RandDecInRange(20, 30, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure PositiveAdjmt_OnPositiveInventory()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
        OldInventory: Integer;
    begin
        Initialize();

        CreateNumberOfItem(Item);
        OldInventory := LibraryRandom.RandIntInRange(20, 30);
        PostItemPurchase(Item, '', OldInventory);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := OldInventory + LibraryRandom.RandDec(10, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeAdjmt_OnPositiveInventory()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
        OldInventory: Integer;
    begin
        Initialize();

        CreateNumberOfItem(Item);
        OldInventory := LibraryRandom.RandIntInRange(20, 30);
        PostItemPurchase(Item, '', OldInventory);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := OldInventory - LibraryRandom.RandDec(10, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure PositiveAdjmt_OnNegativeInventory()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
        OldInventory: Integer;
    begin
        Initialize();

        CreateNumberOfItem(Item);
        OldInventory := -LibraryRandom.RandIntInRange(20, 30);
        PostItemPurchase(Item, '', OldInventory);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := OldInventory + LibraryRandom.RandDec(10, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeAdjmt_OnNegativeInventory()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
        OldInventory: Integer;
    begin
        Initialize();

        CreateNumberOfItem(Item);
        OldInventory := -LibraryRandom.RandIntInRange(20, 30);
        PostItemPurchase(Item, '', OldInventory);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := OldInventory - LibraryRandom.RandDec(10, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure ZeroAdjmt()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        OldInventory: Integer;
    begin
        Initialize();

        CreateNumberOfItem(Item);
        OldInventory := LibraryRandom.RandIntInRange(20, 30);
        PostItemPurchase(Item, '', OldInventory);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        LibraryVariableStorage.Enqueue(OldInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, OldInventory);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustmentWithMinusQuantity()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
        OldInventory: Integer;
    begin
        Initialize();

        CreateNumberOfItem(Item);
        OldInventory := LibraryRandom.RandIntInRange(20, 30);
        PostItemPurchase(Item, '', OldInventory);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := -LibraryRandom.RandDec(10, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustmentWithMinusQuantityOnNegativeInventory()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
        OldInventory: Integer;
    begin
        Initialize();

        CreateNumberOfItem(Item);
        OldInventory := -LibraryRandom.RandIntInRange(20, 30);
        PostItemPurchase(Item, '', OldInventory);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := -LibraryRandom.RandIntInRange(40, 50);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemCardInventoryVerifyDrillDownFoundation()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemCard: TestPage "Item Card";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [FEATURE] [Foundation]
        // [SCENARIO 265064] DrillDown button in the "Inventory" field of the item card opens the list of item ledger entries copmosing the inventory value, when "Basic" application area is enabled

        Initialize();

        // [GIVEN] Enable #Basic application area
        LibraryApplicationArea.EnableFoundationSetup();

        // [GIVEN] Open item card and navigate to an item with posted item ledger entries
        MockItemLedgerEntry(ItemLedgerEntry);
        OpenItemCardWithFilters(ItemCard, ItemLedgerEntry);

        // [WHEN] Drill down on the "Inventory" field
        ItemLedgerEntries.Trap();
        ItemCard.Inventory.DrillDown();

        // [THEN] List of item ledger entries opens, filters from item card are applied to the "Item Ledger Entries" page
        VerifyILEFilters(ItemLedgerEntries, ItemLedgerEntry);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemCardInventoryVerifyDrillDownNoFoundation()
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemCard: TestPage "Item Card";
        ItemLedgerEntries: TestPage "Item Ledger Entries";
    begin
        // [SCENARIO 265064] DrillDown button in the "Inventory" field of the item card opens the list of item ledger entries copmosing the inventory value, when application area setup is disabled

        Initialize();

        // [GIVEN] Disable application area setup
        LibraryApplicationArea.DisableApplicationAreaSetup();

        // [GIVEN] Open item card and navigate to an item with posted item ledger entries
        MockItemLedgerEntry(ItemLedgerEntry);
        OpenItemCardWithFilters(ItemCard, ItemLedgerEntry);

        ItemLedgerEntries.Trap();
        ItemCard.Inventory.DrillDown();

        // [THEN] List of item ledger entries opens, filters from item card are applied to the "Item Ledger Entries" page
        VerifyILEFilters(ItemLedgerEntries, ItemLedgerEntry);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryFilterByLocationModalPageHandler')]
    [Scope('OnPrem')]
    procedure LocationWithMandatoryBinCannotBeUsedInAdjustInventory()
    var
        Item: Record Item;
        Location: Record Location;
        ItemList: TestPage "Item List";
    begin
        // [FEATURE] [Location] [Bin] [UT] [UI]
        // [SCENARIO 319788] You cannot update inventory via Adjust Inventory on a location with mandatory bin.
        Initialize();
        LibraryApplicationArea.EnableLocationsSetup();

        LibraryInventory.CreateItem(Item);

        LibraryWarehouse.CreateLocation(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);

        ItemList.OpenEdit();
        ItemList.FILTER.SetFilter("No.", Item."No.");

        LibraryVariableStorage.Enqueue(Location.Code);
        ItemList.AdjustInventory.Invoke();

        Assert.IsFalse(
          LibraryVariableStorage.DequeueBoolean(), 'Locations with mandatory bin are not available for Adjust Inventory.');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    procedure ClearTemporaryJournalBatchWhenInventoryIsNotAdjusted()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemCard: TestPage "Item Card";
        NoOfBatches: Integer;
    begin
        // [FEATURE] [UT]
        // [SCENARIO 432933] Clear temporary item journal batch when inventory is not adjusted.
        Initialize();

        LibraryInventory.CreateItem(Item);

        NoOfBatches := ItemJournalBatch.Count();

        ItemCard.OpenEdit();
        ItemCard.FILTER.SetFilter("No.", Item."No.");

        LibraryVariableStorage.Enqueue(0);
        ItemCard.AdjustInventory.Invoke();

        Assert.AreEqual(NoOfBatches, ItemJournalBatch.Count(), '');

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VerifyQtyToAdjustOnAdjustInventoryCard')]
    procedure QtyToAdjustOnAdjustInventoryPageWithNonSpecifiedLocation()
    var
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 454842] Verify "Qty. to Adjust" on Adjust Inventory page opened in card mode.
        Initialize();

        // [GIVEN] Create item, post 10 pcs to inventory.
        CreateNumberOfItem(Item);
        PostItemPurchase(Item, '', LibraryRandom.RandInt(10));
        Item.CalcFields(Inventory);

        // [WHEN] Open item card and select "Adjust Inventory".
        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");
        LibraryVariableStorage.Enqueue(Item.Inventory);
        ItemCard.AdjustInventory.Invoke();

        // [THEN] "Adjust Inventory" page is opened in "Not-specified-location" mode.
        // [THEN] Set the new quantity = 15 and ensure that "Qty. to Adjust" = 15 - 10 = 5.
        // Verification is done in VerifyQtyToAdjustOnAdjustInventoryCard handler.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('VerifyQtyToAdjustOnAdjustInventoryList')]
    procedure QtyToAdjustOnAdjustInventoryPageByLocations()
    var
        Item: Record Item;
        Location: Record Location;
        ItemCard: TestPage "Item Card";
    begin
        // [SCENARIO 454842] Verify "Qty. to Adjust" on Adjust Inventory page opened in list mode.
        Initialize();
        LibraryApplicationArea.EnableLocationsSetup();

        // [GIVEN] Create item, post 10 pcs to inventory at location "L".
        CreateNumberOfItem(Item);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        PostItemPurchase(Item, Location.Code, LibraryRandom.RandInt(10));
        Item.CalcFields(Inventory);

        // [WHEN] Open item card and select "Adjust Inventory".
        ItemCard.OpenEdit();
        ItemCard.Filter.SetFilter("No.", Item."No.");
        LibraryVariableStorage.Enqueue(Location.Code);
        LibraryVariableStorage.Enqueue(Item.Inventory);
        ItemCard.AdjustInventory.Invoke();

        // [THEN] "Adjust Inventory" page is opened in "By-locations" mode.
        // [THEN] Set the new quantity = 15 and ensure that "Qty. to Adjust" = 15 - 10 = 5.
        // Verification is done in VerifyQtyToAdjustOnAdjustInventoryList handler.

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Adjust Inventory");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Adjust Inventory");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Adjust Inventory");
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SimpleInvModalPageHandler(var AdjustInventory: TestPage "Adjust Inventory")
    var
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo);

        Assert.IsTrue(StrPos(AdjustInventory.Caption, ItemNo) > 0, 'Wrong Item selected.');

        AdjustInventory.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AdjustInventoryModalPageHandler(var AdjustInventory: TestPage "Adjust Inventory")
    begin
        UpdateInventoryField(AdjustInventory, LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AdjustInventoryModalPageHandlerForLocation(var AdjustInventory: TestPage "Adjust Inventory")
    var
        LocationCode: Code[10];
        NewInventory: Decimal;
    begin
        AdjustInventory.Code.AssertEquals('');
        NewInventory := LibraryVariableStorage.DequeueDecimal();
        LocationCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(LocationCode));
        UpdateInventoryFieldForLocation(AdjustInventory, NewInventory, LocationCode);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AdjustInventoryModalPageHandlerForSeveralLocations(var AdjustInventory: TestPage "Adjust Inventory")
    var
        FirstNewInventory: Decimal;
        FirstLocationCode: Code[10];
        SecondNewInventory: Decimal;
        SecondLocationCode: Code[10];
    begin
        AdjustInventory.Code.AssertEquals('');
        FirstNewInventory := LibraryVariableStorage.DequeueDecimal();
        FirstLocationCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(FirstLocationCode));
        SecondNewInventory := LibraryVariableStorage.DequeueDecimal();
        SecondLocationCode := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(SecondLocationCode));
        UpdateInventoryFieldForSeveralLocation(AdjustInventory, FirstNewInventory,
          FirstLocationCode, SecondNewInventory, SecondLocationCode);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AdjustInventoryFilterByLocationModalPageHandler(var AdjustInventory: TestPage "Adjust Inventory")
    begin
        AdjustInventory.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(AdjustInventory.First());
    end;

    [ModalPageHandler]
    procedure VerifyQtyToAdjustOnAdjustInventoryCard(var AdjustInventory: TestPage "Adjust Inventory")
    var
        CurrentInventory: Decimal;
        NewInventory: Decimal;
    begin
        CurrentInventory := AdjustInventory.CurrentInventoryNoLocation.AsDecimal();
        Assert.AreEqual(LibraryVariableStorage.DequeueDecimal(), CurrentInventory, '');
        NewInventory := CurrentInventory + LibraryRandom.RandInt(10);
        AdjustInventory.NewInventoryNoLocation.SetValue(NewInventory);
        AdjustInventory.QtyToAdjustNoLocation.AssertEquals(NewInventory - CurrentInventory);

        AdjustInventory.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure VerifyQtyToAdjustOnAdjustInventoryList(var AdjustInventory: TestPage "Adjust Inventory")
    var
        CurrentInventory: Decimal;
        NewInventory: Decimal;
    begin
        AdjustInventory.Filter.SetFilter(Code, LibraryVariableStorage.DequeueText());
        CurrentInventory := AdjustInventory.CurrentInventory.AsDecimal();
        Assert.AreEqual(LibraryVariableStorage.DequeueDecimal(), CurrentInventory, '');
        NewInventory := CurrentInventory + LibraryRandom.RandInt(10);
        AdjustInventory.NewInventory.SetValue(NewInventory);
        AdjustInventory.QtyToAdjust.AssertEquals(NewInventory - CurrentInventory);

        AdjustInventory.Cancel().Invoke();
    end;

    local procedure CreateNumberOfItem(var MyItem: Record Item)
    var
        Item0: Record Item;
        Item1: Record Item;
    begin
        LibrarySmallBusiness.CreateItem(Item0);
        LibrarySmallBusiness.CreateItem(MyItem);
        LibrarySmallBusiness.CreateItem(Item1);
    end;

    local procedure MockItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);

        ItemLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemLedgerEntry, ItemLedgerEntry.FieldNo("Entry No."));
        ItemLedgerEntry."Item No." := Item."No.";
        ItemLedgerEntry."Global Dimension 1 Code" :=
          LibraryUtility.GenerateRandomCode(ItemLedgerEntry.FieldNo("Global Dimension 1 Code"), DATABASE::"Item Ledger Entry");
        ItemLedgerEntry."Global Dimension 2 Code" :=
          LibraryUtility.GenerateRandomCode(ItemLedgerEntry.FieldNo("Global Dimension 2 Code"), DATABASE::"Item Ledger Entry");
        ItemLedgerEntry."Location Code" := LibraryUtility.GenerateRandomCode(ItemLedgerEntry.FieldNo("Location Code"), DATABASE::"Item Ledger Entry");
        ItemLedgerEntry."Variant Code" := LibraryUtility.GenerateRandomCode(ItemLedgerEntry.FieldNo("Variant Code"), DATABASE::"Item Ledger Entry");
        ItemLedgerEntry."Lot No." := LibraryUtility.GenerateRandomCode(ItemLedgerEntry.FieldNo("Lot No."), DATABASE::"Item Ledger Entry");
        ItemLedgerEntry."Serial No." := LibraryUtility.GenerateRandomCode(ItemLedgerEntry.FieldNo("Serial No."), DATABASE::"Item Ledger Entry");
        ItemLedgerEntry.Insert();
    end;

    local procedure OpenItemCardWithFilters(var ItemCard: TestPage "Item Card"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        ItemCard.OpenView();
        ItemCard.FILTER.SetFilter("Location Filter", ItemLedgerEntry."Location Code");
        ItemCard.FILTER.SetFilter("Global Dimension 1 Filter", ItemLedgerEntry."Global Dimension 1 Code");
        ItemCard.FILTER.SetFilter("Global Dimension 2 Filter", ItemLedgerEntry."Global Dimension 2 Code");
        ItemCard.FILTER.SetFilter("Variant Filter", ItemLedgerEntry."Variant Code");
        ItemCard.FILTER.SetFilter("Lot No. Filter", ItemLedgerEntry."Lot No.");
        ItemCard.FILTER.SetFilter("Serial No. Filter", ItemLedgerEntry."Serial No.");
        ItemCard.GotoKey(ItemLedgerEntry."Item No.");
    end;

    [Scope('OnPrem')]
    procedure PostItemPurchase(Item: Record Item; LocationCode: Code[10]; Quantity: Integer)
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase,
          Item."No.", Quantity);
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure UpdateInventoryField(var AdjustInventory: TestPage "Adjust Inventory"; NewInventory: Decimal): Decimal
    begin
        AdjustInventory.NewInventory.Value := Format(NewInventory);
        Commit();
        AdjustInventory.OK().Invoke();

        exit(NewInventory)
    end;

    local procedure UpdateInventoryFieldForLocation(var AdjustInventory: TestPage "Adjust Inventory"; NewInventory: Decimal; LocationCode: Code[10]): Decimal
    begin
        AdjustInventory.GotoKey(LocationCode);
        AdjustInventory.NewInventory.Value := Format(NewInventory);
        Commit();
        AdjustInventory.OK().Invoke();

        exit(NewInventory)
    end;

    local procedure UpdateInventoryFieldForSeveralLocation(var AdjustInventory: TestPage "Adjust Inventory"; FirstNewInventory: Decimal; FirstLocationCode: Code[10]; SecondNewInventory: Decimal; SecondLocationCode: Code[10])
    begin
        AdjustInventory.GotoKey(FirstLocationCode);
        AdjustInventory.NewInventory.Value := Format(FirstNewInventory);
        AdjustInventory.GotoKey(SecondLocationCode);
        AdjustInventory.NewInventory.Value := Format(SecondNewInventory);
        Commit();
        AdjustInventory.OK().Invoke();
    end;

    local procedure ValidateNewInventory(var Item: Record Item; ExpectedInventory: Decimal)
    begin
        Item.CalcFields(Inventory);
        Assert.AreEqual(Item.Inventory, ExpectedInventory, 'Inventory updated incorrectly.');
    end;

    local procedure ValidateNewInventoryForLocation(var Item: Record Item; ExpectedInventory: Decimal; LocationCode: Code[10])
    begin
        Item.SetFilter("Location Filter", '%1', LocationCode);
        Item.CalcFields(Inventory);
        Assert.AreEqual(Item.Inventory, ExpectedInventory, 'Inventory updated incorrectly.');
    end;

    local procedure VerifyILEFilters(ItemLedgerEntries: TestPage "Item Ledger Entries"; ItemLedgerEntry: Record "Item Ledger Entry")
    begin
        Assert.IsFalse(ItemLedgerEntries.Editable(), 'Page must not be editable');
        Assert.AreEqual(ItemLedgerEntry."Item No.", ItemLedgerEntries."Item No.".Value, WrongDrillDownValueErr);
        Assert.AreEqual(
          ItemLedgerEntry."Global Dimension 1 Code", ItemLedgerEntries.FILTER.GetFilter("Global Dimension 1 Code"), UnexpectedFilterErr);
        Assert.AreEqual(
          ItemLedgerEntry."Global Dimension 2 Code", ItemLedgerEntries.FILTER.GetFilter("Global Dimension 2 Code"), UnexpectedFilterErr);
        Assert.AreEqual(ItemLedgerEntry."Location Code", ItemLedgerEntries.FILTER.GetFilter("Location Code"), UnexpectedFilterErr);
        Assert.AreEqual(ItemLedgerEntry."Variant Code", ItemLedgerEntries.FILTER.GetFilter("Variant Code"), UnexpectedFilterErr);
        Assert.AreEqual(ItemLedgerEntry."Lot No.", ItemLedgerEntries.FILTER.GetFilter("Lot No."), UnexpectedFilterErr);
        Assert.AreEqual(ItemLedgerEntry."Serial No.", ItemLedgerEntries.FILTER.GetFilter("Serial No."), UnexpectedFilterErr);
    end;

    local procedure GetLocation(): Code[10]
    var
        Location: Record Location;
        LocationCode: Code[10];
    begin
        LocationCode := 'A' + Format(LibraryRandom.RandIntInRange(0, 100));

        while Location.Get(LocationCode) do
            LocationCode := 'A' + Format(LibraryRandom.RandIntInRange(0, 100));

        Location.Init();
        Location.Validate(Code, LocationCode);
        Location.Validate(Name, LocationCode);
        Location.Insert(true);
        LibraryInventory.UpdateInventoryPostingSetup(Location);
        Location.Modify(true);

        exit(Location.Code);
    end;

    local procedure CreateAndPostItem(var Item: Record Item; var LocationCode: Code[10])
    begin
        CreateNumberOfItem(Item);
        LocationCode := GetLocation();
        CreateAndPostItemJournalLine(Item."No.", LocationCode, LibraryRandom.RandDecInRange(0, 10, 2));
    end;

    local procedure CreateAndPostItemJournalLine(ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        SelectAndClearItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Quantity);

        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure SelectAndClearItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalBatch."Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;
}

