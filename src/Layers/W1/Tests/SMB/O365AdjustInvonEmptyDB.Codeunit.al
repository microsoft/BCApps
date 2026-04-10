codeunit 138031 "O365 Adjust Inv. on Empty DB"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Adjust Inventory] [Empty DB] [SMB]
        isInitialized := false;
    end;

    var
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySmallBusiness: Codeunit "Library - Small Business";
        LibraryFiscalYear: Codeunit "Library - Fiscal Year";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure PositiveAdjmtOnEmptyDB()
    var
        Item: Record Item;
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
    begin
        Initialize();

        ItemJnlTemplate.DeleteAll();
        ItemJnlBatch.DeleteAll();

        CreateNumberOfItem(Item);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := LibraryRandom.RandDecInRange(20, 30, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    [Test]
    [HandlerFunctions('AdjustInventoryModalPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeAdjmtOnEmptyDB()
    var
        Item: Record Item;
        ItemJnlTemplate: Record "Item Journal Template";
        ItemJnlBatch: Record "Item Journal Batch";
        ItemCard: TestPage "Item Card";
        NewInventory: Decimal;
    begin
        Initialize();

        ItemJnlTemplate.DeleteAll();
        ItemJnlBatch.DeleteAll();

        CreateNumberOfItem(Item);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);

        NewInventory := -LibraryRandom.RandDecInRange(20, 30, 2);
        LibraryVariableStorage.Enqueue(NewInventory);
        ItemCard.AdjustInventory.Invoke();

        ValidateNewInventory(Item, NewInventory);
    end;

    local procedure Initialize()
    var
        LibraryApplicationArea: Codeunit "Library - Application Area";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"O365 Adjust Inv. on Empty DB");
        LibraryVariableStorage.Clear();
        LibraryApplicationArea.EnableFoundationSetup();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"O365 Adjust Inv. on Empty DB");

        if not LibraryFiscalYear.AccountingPeriodsExists() then
            LibraryFiscalYear.CreateFiscalYear();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"O365 Adjust Inv. on Empty DB");
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

    local procedure UpdateInventoryField(var AdjustInventory: TestPage "Adjust Inventory"; NewInventory: Decimal): Decimal
    begin
        AdjustInventory.NewInventory.Value := Format(NewInventory);
        Commit();
        AdjustInventory.OK().Invoke();

        exit(NewInventory)
    end;

    local procedure ValidateNewInventory(var Item: Record Item; ExpectedInventory: Decimal)
    begin
        Item.CalcFields(Inventory);
        Assert.AreEqual(Item.Inventory, ExpectedInventory, 'Inventory updated incorrectly.');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AdjustInventoryModalPageHandler(var AdjustInventory: TestPage "Adjust Inventory")
    var
        NewInventory: Decimal;
    begin
        NewInventory := LibraryVariableStorage.DequeueDecimal();
        UpdateInventoryField(AdjustInventory, NewInventory);
    end;
}

