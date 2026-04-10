codeunit 134122 "Price Asset List UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Asset] [List]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;

    [Test]
    procedure T001_AddAssetItemWithItemDiscount()
    var
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        Item.Modify();
        // [WHEN] Add "Item" 'I', where "Item Disc. Group" is 'D', at level 7
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Item, Item."No.");
        // [THEN] GetList returns three records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 4);
        // [THEN] Item Discount Group 'D', where Level is 7
        TempPriceAsset.FindFirst();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Item Discount Group");
        TempPriceAsset.TestField("Asset No.", ItemDiscountGroup.Code);
        TempPriceAsset.TestField(Level, Level);
        // [THEN] (All) Item Discount Groups, where Level is 6
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Item Discount Group");
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] (All) Items, where Level is 6
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Item);
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] Item 'I', where Level is 7
        TempPriceAsset.FindLast();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Item);
        TempPriceAsset.TestField("Asset No.", Item."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T002_AddAssetItemWithoutItemDiscount()
    var
        Item: Record Item;
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        Item."Item Disc. Group" := '';
        Item.Modify();
        // [WHEN] Add "Item" 'I', where "Item Disc. Group" is <blank>, at level 7
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Item, Item."No.");
        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] (All) Items, where Level is 6
        TempPriceAsset.FindFirst();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Item);
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] Item 'I', where Level is 7
        TempPriceAsset.FindLast();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Item);
        TempPriceAsset.TestField("Asset No.", Item."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T003_AddAssetItemWithDeletedItemDiscount()
    var
        Item: Record Item;
        ItemDiscountGroup: Record "Item Discount Group";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        Item."Item Disc. Group" := ItemDiscountGroup.Code;
        Item.Modify();
        // [GIVEN] "Item Disc. Group" 'D' is deleted
        ItemDiscountGroup.Delete();
        // [WHEN] Add "Item" 'I', where "Item Disc. Group" is 'D', at level 7
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Item, Item."No.");
        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] (All) Items, where Level is 6
        TempPriceAsset.FindFirst();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Item);
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] Item 'I', where Level is 7
        TempPriceAsset.FindLast();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Item);
        TempPriceAsset.TestField("Asset No.", Item."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T010_AddAssetResourceWithResourceGroup()
    var
        Resource: Record Resource;
        ResourceGroup: Record "Resource Group";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryResource.CreateResourceGroup(ResourceGroup);
        LibraryResource.CreateResource(Resource, '');
        Resource."Resource Group No." := ResourceGroup."No.";
        Resource.Modify();
        // [WHEN] Add "Resource" 'R', where "Resource Group No." is 'G', at level 5
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Resource, Resource."No.");

        // [THEN] GetList returns four records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 4);
        TempPriceAsset.SetCurrentKey(Level);
        // [THEN] All resource groups, where Level is 3
        TempPriceAsset.FindSet();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Resource Group");
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 2);
        // [THEN] Resource <blank> (for all resources), where Level is 3
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Resource);
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 2);
        // [THEN] Resource Group 'G', where Level is 4
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Resource Group");
        TempPriceAsset.TestField("Asset No.", ResourceGroup."No.");
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] Resource 'R', where Level is 5
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Resource);
        TempPriceAsset.TestField("Asset No.", Resource."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T011_AddAssetResourceWithoutResourceGroup()
    var
        Resource: Record Resource;
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryResource.CreateResource(Resource, '');
        Resource."Resource Group No." := '';
        Resource.Modify();
        // [WHEN] Add "Resource Group" 'R', at level 5
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Resource, Resource."No.");

        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] Resource <blank> (for all resources), where Level is 3
        TempPriceAsset.FindSet();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Resource);
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 2);
        // [THEN] Resource 'R', where Level is 5
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::Resource);
        TempPriceAsset.TestField("Asset No.", Resource."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T020_AddAssetResourceGroup()
    var
        ResourceGroup: Record "Resource Group";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryResource.CreateResourceGroup(ResourceGroup);
        // [WHEN] Add "Resource" 'R', where "Resource Group No." is <blank>, at level 5
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::"Resource Group", ResourceGroup."No.");

        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] Resource Group <blank> (for all resource groups), where Level is 4
        TempPriceAsset.FindSet();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Resource Group");
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] Resource Group 'R', where Level is 5
        TempPriceAsset.Next();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Resource Group");
        TempPriceAsset.TestField("Asset No.", ResourceGroup."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T030_AddAssetGLAccount()
    var
        GLAccount: Record "G/L Account";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryERM.CreateGLAccount(GLAccount);
        // [WHEN] Add "G/L Account" 'A' at level 7
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::"G/L Account", GLAccount."No.");
        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] (All) G/L Accounts, where Level is 6
        TempPriceAsset.FindFirst();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"G/L Account");
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] G/L Account 'A', where Level is 7
        TempPriceAsset.FindLast();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"G/L Account");
        TempPriceAsset.TestField("Asset No.", GLAccount."No.");
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T040_AddAssetItemDiscGroup()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        // [WHEN] Add "Item Discount Group" 'I' at level 7
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::"Item Discount Group", ItemDiscountGroup.Code);
        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] (All) Item Discount Groups, where Level is 6
        TempPriceAsset.FindFirst();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Item Discount Group");
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] Item Discount Group 'I', where Level is 7
        TempPriceAsset.FindLast();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Item Discount Group");
        TempPriceAsset.TestField("Asset No.", ItemDiscountGroup.Code);
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T050_AddAssetServiceCost()
    var
        ServiceCost: Record "Service Cost";
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryService.CreateServiceCost(ServiceCost);
        // [WHEN] Add "Service Cost" 'S' at level 7
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::"Service Cost", ServiceCost.Code);
        // [THEN] GetList returns two records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] (All) Service Costs, where Level is 6
        TempPriceAsset.FindFirst();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Service Cost");
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] Service Cost 'S', where Level is 7
        TempPriceAsset.FindLast();
        TempPriceAsset.TestField("Asset Type", TempPriceAsset."Asset Type"::"Service Cost");
        TempPriceAsset.TestField("Asset No.", ServiceCost.Code);
        TempPriceAsset.TestField(Level, Level);
    end;

    [Test]
    procedure T100_RemoveAssetFromList()
    var
        Item: Record Item;
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Add "Item" 'I' at level 7
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Item, Item."No.");
        // [WHEN] Remove 'Item'
        PriceAssetList.Remove(AssetType::Item);

        // [THEN] GetList returns 0 records
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 0);
    end;

    [Test]
    procedure T101_RemoveAssetFromListAtLevel()
    var
        Item: Record Item;
        TempPriceAsset: Record "Price Asset" temporary;
        PriceAssetList: Codeunit "Price Asset List";
        AssetType: Enum "Price Asset Type";
        Level: Integer;
    begin
        Initialize();
        LibraryInventory.CreateItem(Item);
        // [GIVEN] Add "Item" at level 7 and at level 8
        Level := LibraryRandom.RandInt(10);
        PriceAssetList.SetLevel(Level);
        PriceAssetList.Add(AssetType::Item, Item."No.");
        PriceAssetList.IncLevel();
        PriceAssetList.Add(AssetType::Item, Item."No.");

        // [WHEN] Remove 'Item' at level 7
        PriceAssetList.RemoveAtLevel(AssetType::Item, Level);

        // [THEN] GetList returns 2 records:
        PriceAssetList.GetList(TempPriceAsset);
        Assert.RecordCount(TempPriceAsset, 2);
        // [THEN] (All items) at level 6
        TempPriceAsset.FindFirst();
        TempPriceAsset.TestField("Asset No.", '');
        TempPriceAsset.TestField(Level, Level - 1);
        // [THEN] Item at level 8 
        TempPriceAsset.FindLast();
        TempPriceAsset.TestField("Asset No.", Item."No.");
        TempPriceAsset.TestField(Level, Level + 1);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price Asset List UT");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price Asset List UT");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price Asset List UT");
    end;


}