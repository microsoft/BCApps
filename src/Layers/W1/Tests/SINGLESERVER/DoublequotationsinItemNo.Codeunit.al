codeunit 132902 "Double quotations in Item No."
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item] [Stockkeeping Units]
    end;

    var
        StockKeepingUnitNotCreatedErr: Label 'Test failed, stockkeeping unit for test item string %1 is not created.';
        LibraryInventory: Codeunit "Library - Inventory";

    [Test]
    [HandlerFunctions('RequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckCreatingStockkeepingUnit()
    begin
        // [SCENARIO 276233] Double quotations can be used in the Item No. field on the Item when creating Stockkeeping Units.
        InternalCreateItem('"TEST" "2"');
        InternalCreateItem('"""');
        InternalCreateItem('"!!!@@@');
        InternalCreateItem('"###$$$');
        InternalCreateItem('"%%%^^^');
        InternalCreateItem('"***');
        InternalCreateItem('"___+++');
        InternalCreateItem('"|???');
        InternalCreateItem('"---~~~');
        InternalCreateItem('"{{{}}}[[[');
        InternalCreateItem('"]]]\\\');

        InternalCheckStockkeepingUnit('"TEST" "2"');
        InternalCheckStockkeepingUnit('"""');
        InternalCheckStockkeepingUnit('"!!!@@@');
        InternalCheckStockkeepingUnit('"###$$$');
        InternalCheckStockkeepingUnit('"%%%^^^');
        InternalCheckStockkeepingUnit('"***');
        InternalCheckStockkeepingUnit('"___+++');
        InternalCheckStockkeepingUnit('"|???');
        InternalCheckStockkeepingUnit('"---~~~');
        InternalCheckStockkeepingUnit('"{{{}}}[[[');
        InternalCheckStockkeepingUnit('"]]]\\\');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CleanUp()
    begin
        InternalCleanup('"TEST" "2"');
        InternalCleanup('"""');
        InternalCleanup('"!!!@@@');
        InternalCleanup('"###$$$');
        InternalCleanup('"%%%^^^');
        InternalCleanup('"***');
        InternalCleanup('"___+++');
        InternalCleanup('"|???');
        InternalCleanup('"---~~~');
        InternalCleanup('"{{{}}}[[[');
        InternalCleanup('"]]]\\\');
    end;

    [Normal]
    local procedure InternalCleanup(No: Text)
    var
        ItemObj: Record Item;
        StockkeepingUnitObj: Record "Stockkeeping Unit";
        ItemUnitOfMeasureObj: Record "Item Unit of Measure";
    begin
        if ItemObj.Get(No) then
            ItemObj.Delete();
        if StockkeepingUnitObj.Get(No) then
            StockkeepingUnitObj.Delete();
        ItemUnitOfMeasureObj.SetRange("Item No.", No);
        if ItemUnitOfMeasureObj.FindFirst() then
            ItemUnitOfMeasureObj.Delete();
        Commit();
    end;

    [Normal]
    local procedure InternalCreateItem(ItemNo: Text[20])
    var
        ItemUnitOfMeasureObj: Record "Item Unit of Measure";
        Item: Record Item;
        ItemCard: TestPage "Item Card";
    begin
        LibraryInventory.CreateItem(Item);
        Item.Rename(ItemNo);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasureObj, ItemNo, 1);

        ItemCard.OpenEdit();
        ItemCard.GotoRecord(Item);
        ItemCard."Base Unit of Measure".Value := ItemUnitOfMeasureObj.Code;
        ItemCard."Inventory Posting Group".Value := GetInventoryPostingGroup();
        ItemCard."Gen. Prod. Posting Group".Value := GetGenProdPostingGroup();
        ItemCard.OK().Invoke();
        Commit();
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        ItemCard."&Create Stockkeeping Unit".Invoke();
        ItemCard.OK().Invoke();
    end;

    [Normal]
    local procedure InternalCheckStockkeepingUnit(No: Text[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.SetFilter("Item No.", No);

        if not StockkeepingUnit.FindFirst() then
            Error(StockKeepingUnitNotCreatedErr, No);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestPageHandler(var CreateStockkeepingUnit: TestRequestPage "Create Stockkeeping Unit")
    begin
        CreateStockkeepingUnit.Item.SetFilter("Location Filter", GetLocationCode());
        CreateStockkeepingUnit.SKUCreationMethod.Value := CreateStockkeepingUnit.SKUCreationMethod.GetOption("SKU Creation Method"::Location.AsInteger() + 1);
        CreateStockkeepingUnit.OK().Invoke();
    end;

    local procedure GetInventoryPostingGroup(): Code[20]
    var
        InventoryPostingGroup: Record "Inventory Posting Group";
    begin
        InventoryPostingGroup.FindFirst();
        exit(InventoryPostingGroup.Code);
    end;

    local procedure GetGenProdPostingGroup(): Code[20]
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
    begin
        GenProductPostingGroup.FindFirst();
        exit(GenProductPostingGroup.Code);
    end;

    local procedure GetLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        Location.FindFirst();
        exit(Location.Code);
    end;
}

