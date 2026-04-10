codeunit 134827 "UT Item Table"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Find Item] [UT]
    end;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        ItemNotRegisteredTxt: Label 'This item is not registered. To continue, choose one of the following options:';
        ItemNameWithFilterCharsTxt: Label '&I*t|e(m''I)t)e&m*';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        CodeCoverageMgt: Codeunit "Code Coverage Mgt.";
        isInitialized: Boolean;
        InternationalUoMEachTxt: Label 'EA', Locked = true;
        NonExistingInternationalUoMTxt: Label 'NOTEXIST', Locked = true;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemNoGetItemByExactNo()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2);

        CreateItemFromNo(Item1, RandomText1);
        CreateItemFromNo(Item2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Item
        Assert.AreEqual(Item1."No.", Item1.GetItemNo(RandomText1), 'Item not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemNoGetItemByStartNo()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2 - 1);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2);

        CreateItemFromNo(Item1, RandomText1);
        CreateItemFromNo(Item2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Item
        Assert.AreEqual(Item1."No.", Item1.GetItemNo(CopyStr(RandomText1, 1, 8)), 'Item not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemNoGetItemByPartNo()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2 - 2);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2);

        CreateItemFromNo(Item1, RandomText1);
        CreateItemFromNo(Item2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Item
        Assert.AreEqual(Item2."No.", Item2.GetItemNo(CopyStr(RandomText2, 2, 8)), 'Item not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemNoGetItemByExactName()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1.Description) / 2);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1.Description) / 2);

        CreateItemFromName(Item1, RandomText1 + RandomText2);
        CreateItemFromName(Item2, RandomText1);

        // Exercise and Verify Existing Item
        Assert.AreEqual(Item2."No.", Item2.GetItemNo(RandomText1), 'Item not found');
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('SelectionFirstItemFromItemListModalPageHandler')]
    procedure TestGetItemNoGetItemByStartOfName()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1.Description) / 2);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1.Description) / 2);

        CreateItemFromName(Item1, RandomText1 + RandomText2);
        CreateItemFromName(Item2, RandomText1);

        // Exercise and Verify Existing Item
        Assert.AreEqual(Item1."No.", Item1.GetItemNo(CopyStr(RandomText1, 1, 10)), 'Item not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemNoGetItemByPartOfName()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1.Description) / 2);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1.Description) / 2);

        CreateItemFromName(Item1, RandomText1 + RandomText2);
        CreateItemFromName(Item2, RandomText1);

        // Exercise and Verify Existing Item
        Assert.AreEqual(Item1."No.", Item1.GetItemNo(CopyStr(RandomText2, 5, 10)), 'Item not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemNoGetItemByPartOfBaseUnitofMeasure()
    var
        Item: Record Item;
        UOM: Record "Unit of Measure";
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateUnitOfMeasureCode(UOM);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Base Unit of Measure", UOM.Code);
        Item.Modify(true);

        // Exercise and Verify Existing Item
        Assert.AreEqual(Item."No.", Item.GetItemNo(CopyStr(Item."Base Unit of Measure", 5, 10)), 'Item not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateItemUsingInternationalUnitOfMeasure()
    var
        Item: Record Item;
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateItem(Item);

        // Exercise
        // Use the UOM International Standard Code, instead of Base Unit Of Measure
        Item.Validate("Base Unit of Measure", InternationalUoMEachTxt);
        Item.Modify(true);

        // Verify Item Base Unit of Measure
        Assert.AreNotEqual(Item."Base Unit of Measure", InternationalUoMEachTxt,
          StrSubstNo('Item Base Unit of Measure should not be equal to %1', InternationalUoMEachTxt));
        Assert.AreNotEqual(Item."Sales Unit of Measure", InternationalUoMEachTxt,
          StrSubstNo('Item Sales Unit of Measure should not be equal to %1', InternationalUoMEachTxt));
        Assert.AreNotEqual(Item."Purch. Unit of Measure", InternationalUoMEachTxt,
          StrSubstNo('Item Purch. Unit of Measure should not be equal to %1', InternationalUoMEachTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestCreateItemForNonExistingUOM()
    var
        Item: Record Item;
    begin
        Initialize();

        // Setup
        LibraryInventory.CreateItem(Item);

        // Exercise and Verify
        // Use the UOM International Standard Code, instead of Base Unit Of Measure
        asserterror Item.Validate("Base Unit of Measure", NonExistingInternationalUoMTxt);
        Assert.ExpectedError(StrSubstNo('The Unit of Measure with Code %1 does not exist.', NonExistingInternationalUoMTxt));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemNoGetItemByPartOfNameIncludingFilterChars()
    var
        Item: Record Item;
    begin
        Initialize();

        // Setup
        CreateItemFromName(Item, ItemNameWithFilterCharsTxt);

        // Exercise and Verify Existing Item
        Assert.AreEqual(Item."No.", Item.GetItemNo(ItemNameWithFilterCharsTxt), 'Item not found');
    end;

    [Test]
    [HandlerFunctions('ItemNotRegisteredStrMenuHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestGetItemNoGetItemByNoInputOverflow()
    var
        Item: Record Item;
        ReturnValue: Text[50];
    begin
        Initialize();
        // Offset the random
        LibraryUtility.GenerateRandomText(1);

        // Setup
        CreateItemFromNo(Item, LibraryUtility.GenerateRandomText(MaxStrLen(Item."No.")));

        // Exercise
        asserterror Item.TryGetItemNo(ReturnValue, Item."No." + 'Extra Text', true);
        Assert.ExpectedError('');
    end;

    [Test]
    [HandlerFunctions('ItemNotRegisteredStrMenuHandlerCancel')]
    [Scope('OnPrem')]
    procedure TestGetItemNoPromptCreateItem()
    var
        Item: Record Item;
        NoneExixtingItemNo: Code[20];
        ReturnValue: Text[50];
    begin
        Initialize();

        // Setup
        NoneExixtingItemNo := LibraryInventory.CreateItemNo();
        Item.Get(NoneExixtingItemNo);
        Item.Delete();

        // Exercise and Verify None Existing Item
        asserterror Item.TryGetItemNo(ReturnValue, NoneExixtingItemNo, true);
        Assert.ExpectedError('');
        // Confirm handler will verify the confirm and skip creation of Item
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemNoReturnInputText()
    var
        Item: Record Item;
        NoneExixtingItemNo: Code[20];
        ReturnValue: Text[50];
    begin
        Initialize();

        // Setup
        NoneExixtingItemNo := LibraryInventory.CreateItemNo();
        Item.Get(NoneExixtingItemNo);
        Item.Delete();

        // Exercise and Verify None Existing Item
        Item.TryGetItemNo(ReturnValue, NoneExixtingItemNo, false);
        Assert.AreEqual(NoneExixtingItemNo, ReturnValue, 'Expect to return input text');
    end;

    [Test]
    [HandlerFunctions('CancelSelectionOfItemFromItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestGetItemNoPromptPickItemCancel()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
        ReturnValue: Text[50];
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2 - 3);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2);

        CreateItemFromNo(Item1, RandomText1);
        CreateItemFromNo(Item2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Item
        asserterror Item1.TryGetItemNo(ReturnValue, CopyStr(RandomText1, 2, 10), true);
        Assert.ExpectedError('');
        // Confirm handler will verify the Item list opens and cancel selection of Item
    end;

    [Test]
    [HandlerFunctions('VerifyAllItemsShownItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestGetItemNoPromptPickItem()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
        ReturnValue: Text[50];
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2 - 3);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2);

        CreateItemFromNo(Item1, RandomText1);
        CreateItemFromNo(Item2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Item
        Item1.TryGetItemNo(ReturnValue, CopyStr(RandomText1, 2, 10), true);

        // Confirm handler will verify the Item list opens and verifies all items are shown
    end;

    [Test]
    [HandlerFunctions('CancelSelectionOfItemFromItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestGetItemNoCancelPromptPickItem()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
        ReturnValue: Text[50];
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2 - 3);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2);

        CreateItemFromNo(Item1, RandomText1);
        CreateItemFromNo(Item2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Item
        Item1.TryGetItemNo(ReturnValue, CopyStr(RandomText1, 2, 10), false);
        Assert.AreEqual(CopyStr(RandomText1, 2, 10), ReturnValue, 'Expect to return input text');
    end;

    [Test]
    [HandlerFunctions('ItemNotRegisteredStrMenuHandlerPick,VerifyAllItemsShownItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestGetItemSelectFromFullList()
    var
        Item: Record Item;
        ReturnValue: Text[50];
    begin
        Initialize();

        // Setup: Create two items
        LibraryInventory.CreateItemNo();
        LibraryInventory.CreateItemNo();

        // Exercise: Try to get a non-existant item no
        Item.TryGetItemNo(ReturnValue, LibraryUtility.GenerateRandomText(MaxStrLen(Item."No.")), true);
        // Verify: VerifyAllItemsShownItemListModalPageHandler verifies that all items are shown to the user
    end;

    [Test]
    [HandlerFunctions('SelectionFirstItemFromItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestGetItemNoSelectItemFromPickItem()
    var
        Item1: Record Item;
        Item2: Record Item;
        RandomText1: Text;
        RandomText2: Text;
    begin
        Initialize();

        // Setup
        RandomText1 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2 - 3);
        RandomText2 := LibraryUtility.GenerateRandomText(MaxStrLen(Item1."No.") / 2);

        CreateItemFromNo(Item1, RandomText1);
        CreateItemFromNo(Item2, RandomText1 + RandomText2);

        // Exercise and Verify Existing Item
        Assert.AreEqual(Item1."No.", Item1.GetItemNo(CopyStr(RandomText1, 2, 10)), 'Item not found');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestTryGetItemNoInventorySetupSkiPromptCreateNewItemYes()
    var
        Item: Record Item;
        DummyItemText: Text[50];
    begin
        // [SCENARIO 282065] Item.TryGetItemNo function returns FALSE when InventorySetyp."Skip Prompt to Create Item" = TRUE
        Initialize();

        // [GIVEN] Set InventorySetyp."Skip Prompt to Create Item" = Yes
        SetInventorySetupSkipPromptToCreateItemTRUE();

        // [WHEN] Item.TryGetItemNo is being run
        // [THEN] It returns FALSE
        Assert.IsFalse(
          Item.TryGetItemNo(DummyItemText, LibraryUtility.GenerateRandomText(MaxStrLen(Item."No.")), true),
          'TryGetItemNo must return FALSE');
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler,ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure TestLookupItemsListWhenNonExistingItemNoEntered()
    var
        Item: array[10] of Record Item;
        LookupItem: Record Item;
        CodeCoverage: Record "Code Coverage";
        Index: Integer;
        NoOfHits: Integer;
        SubString: Text[10];
        DummyReturnValue: Text;
    begin
        // [FEATURE] [Performance] [ItemList] [UI]
        // [SCENARIO 283579] Stan enters some text in Document Line No., chooses to select Item No. and gets the ItemList page populated with all existing Items, ItemList page is based on real table
        Initialize();

        for Index := 1 to ArrayLen(Item) do
            CreateItemSimple(Item[Index]);

        SubString := LibraryUtility.GenerateGUID();

        CodeCoverageMgt.StartApplicationCoverage();
        LookupItem.TryGetItemNoOpenCard(DummyReturnValue, SubString, true, true, true);
        CodeCoverageMgt.StopApplicationCoverage();

        NoOfHits :=
          GetCodeCoverageForObject(
            CodeCoverage."Object Type"::Table, DATABASE::Item, 'SetTempFilteredItemRec');
        Assert.AreEqual(0, NoOfHits, 'ItemList.SetTempFilteredItemRec must not be called');

        for Index := 1 to ArrayLen(Item) do
            Assert.AreEqual(
              Item[Index]."No.",
              LibraryVariableStorage.DequeueText(),
              'Expected match in Item."No"');

        Assert.AreEqual(
          ArrayLen(Item),
          LibraryVariableStorage.DequeueInteger(),
          StrSubstNo('Expected %1 items in the ItemList page', ArrayLen(Item)));

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemRenameNoAffectsTransferLine()
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        Item: Record Item;
        LocationFrom: Record Location;
        LocationTo: Record Location;
        LocationInTransit: Record Location;
        ItemNoOld: Text;
        ItemNoNew: Text;
    begin
        // [SCENARIO 293567] Changing Item's "No." affects corresponding Transfer Line records
        Initialize();

        // [GIVEN] Created an Item
        ItemNoOld := LibraryUtility.GenerateRandomNumericText(MaxStrLen(Item."No."));
        CreateItemFromNo(Item, ItemNoOld);

        // [GIVEN] Created a Transfer Line with that Item
        LibraryWarehouse.CreateTransferLocations(LocationFrom, LocationTo, LocationInTransit);
        LibraryInventory.CreateTransferHeader(TransferHeader, LocationFrom.Code, LocationTo.Code, LocationInTransit.Code);
        LibraryInventory.CreateTransferLine(TransferHeader, TransferLine, Item."No.", LibraryRandom.RandInt(9));

        // [WHEN] Rename the Item
        ItemNoNew := LibraryUtility.GenerateRandomNumericText(MaxStrLen(Item."No."));
        Item.Rename(ItemNoNew);

        // [THEN] Item in the Corresponding Transfer Line has new value
        TransferLine.Find();
        TransferLine.TestField("Item No.", ItemNoNew);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestGetItemNoGetItemByName_CaseSensitive_Blocked()
    var
        Item: array[4] of Record Item;
        RandomText1: Text[100];
        RandomText2: Text[100];
    begin
        Initialize();

        RandomText1 := 'aaa';
        RandomText2 := 'AAA';

        CreateItemFromNameAndBlocked(Item[1], RandomText1, true);
        CreateItemFromNameAndBlocked(Item[2], RandomText1, false);
        CreateItemFromNameAndBlocked(Item[3], RandomText2, true);
        CreateItemFromNameAndBlocked(Item[4], RandomText2, false);

        Assert.AreEqual(Item[2]."No.", Item[1].GetItemNo(RandomText1), '');
        Assert.AreEqual(Item[4]."No.", Item[1].GetItemNo(RandomText2), '');
    end;

    local procedure Initialize()
    var
        Item: Record Item;
        ObjectOptions: Record "Object Options";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"UT Item Table");
        Item.DeleteAll();
        ObjectOptions.DeleteAll();

        LibrarySetupStorage.Restore();
        if isInitialized then
            exit;

        isInitialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
    end;

    local procedure CreateItemSimple(var Item: Record Item)
    begin
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();
    end;

    local procedure CreateItemFromNo(var Item: Record Item; No: Text)
    begin
        Item.Validate("No.", CopyStr(No, 1, MaxStrLen(Item."No.")));
        Item.Insert(true);
    end;

    local procedure CreateItemFromName(var Item: Record Item; Description: Text)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, CopyStr(Description, 1, MaxStrLen(Item.Description)));
        Item.Modify(true);
    end;

    local procedure CreateItemFromNameAndBlocked(var Item: Record Item; Description: Text; ItemBlocked: Boolean)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Description, CopyStr(Description, 1, MaxStrLen(Item.Description)));
        Item.Validate(Blocked, ItemBlocked);
        Item.Modify(true);
    end;

    local procedure CounStoretItemsFilteredOnPage(var ItemList: TestPage "Item List") "Count": Integer
    begin
        if ItemList.First() then
            repeat
                Count += 1;
                LibraryVariableStorage.Enqueue(ItemList."No.".Value);
            until ItemList.Next() = false;
        exit(Count);
    end;

    local procedure GetCodeCoverageForObject(ObjectType: Option; ObjectID: Integer; CodeLine: Text) NoOfHits: Integer
    var
        CodeCoverage: Record "Code Coverage";
    begin
        CodeCoverageMgt.Refresh();
        CodeCoverage.SetRange("Line Type", CodeCoverage."Line Type"::Code);
        CodeCoverage.SetRange("Object Type", ObjectType);
        CodeCoverage.SetRange("Object ID", ObjectID);
        CodeCoverage.SetFilter("No. of Hits", '>%1', 0);
        CodeCoverage.SetFilter(Line, '@*' + CodeLine + '*');
        if CodeCoverage.FindSet() then
            repeat
                NoOfHits += CodeCoverage."No. of Hits";
            until CodeCoverage.Next() = 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemNotRegisteredStrMenuHandlerCancel(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Assert.ExpectedMessage(ItemNotRegisteredTxt, Instruction);
        Choice := 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure ItemNotRegisteredStrMenuHandlerPick(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Assert.ExpectedMessage(ItemNotRegisteredTxt, Instruction);
        Choice := 2;
    end;

    local procedure SetInventorySetupSkipPromptToCreateItemTRUE()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Skip Prompt to Create Item", true);
        InventorySetup.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CancelSelectionOfItemFromItemListModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListModalPageHandler(var ItemList: TestPage "Item List")
    begin
        LibraryVariableStorage.Enqueue(CounStoretItemsFilteredOnPage(ItemList));
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectionFirstItemFromItemListModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.OK().Invoke();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure VerifyAllItemsShownItemListModalPageHandler(var ItemList: TestPage "Item List")
    var
        Item: Record Item;
    begin
        Item.FindSet();
        repeat
            ItemList."No.".AssertEquals(Item."No.");
            ItemList.Next();
        until Item.Next() = 0;
        ItemList.OK().Invoke();
    end;
}

