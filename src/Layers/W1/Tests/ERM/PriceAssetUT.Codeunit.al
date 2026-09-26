codeunit 134119 "Price Asset UT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Price Calculation] [Asset]
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        AssetNoMustHaveValueErr: Label 'Product No. must have a value';
        IsInitialized: Boolean;

    [Test]
    procedure T001_IsAssetNoRequired()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] All asset types except 'All' return true for IsAssetNoRequired()
        Initialize();

        PriceAsset.Validate("Asset Type", "Price Asset Type"::" ");
        Assert.IsFalse(PriceAsset.IsAssetNoRequired(), 'All');

        PriceAsset.Validate("Asset Type", "Price Asset Type"::"G/L Account");
        Assert.IsTrue(PriceAsset.IsAssetNoRequired(), 'G/L Account');
        PriceAsset.Validate("Asset Type", "Price Asset Type"::Item);
        Assert.IsTrue(PriceAsset.IsAssetNoRequired(), 'Item');
        PriceAsset.Validate("Asset Type", "Price Asset Type"::"Item Discount Group");
        Assert.IsTrue(PriceAsset.IsAssetNoRequired(), 'Item Discount Group');
        PriceAsset.Validate("Asset Type", "Price Asset Type"::Resource);
        Assert.IsTrue(PriceAsset.IsAssetNoRequired(), 'Resource');
        PriceAsset.Validate("Asset Type", "Price Asset Type"::"Resource Group");
        Assert.IsTrue(PriceAsset.IsAssetNoRequired(), 'Resource Group');
        PriceAsset.Validate("Asset Type", "Price Asset Type"::"Service Cost");
        Assert.IsTrue(PriceAsset.IsAssetNoRequired(), 'Service Cost');
    end;


    [Test]
    procedure T010_UnitPriceForItemSale()
    var
        Item: Record Item;
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Item] [Sale]
        Initialize();
        // [GIVEN] Item 'I', where "Unit Price" is 'X'
        LibraryInventory.CreateItem(Item);
        Item."Unit Price" := LibraryRandom.RandDec(100, 2);
        Item.Modify();
        // [GIVEN] Asset, where "Price Type" 'Sale'
        PriceAsset."Price Type" := "Price Type"::Sale;
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        // [WHEN] Validate Item "Asset ID" as SystemId of 'I'
        PriceAsset.Validate("Asset ID", Item.SystemId);
        // [THEN] Asset, where "Unit Price" is 'X'
        PriceAsset.TestField("Unit Price", Item."Unit Price");
    end;

    [Test]
    procedure T011_UnitPriceForItemPurchase()
    var
        Item: Record Item;
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Item] [Purchase]
        Initialize();
        // [GIVEN] Item 'I', where "Last Direct Cost" is 'X'
        LibraryInventory.CreateItem(Item);
        Item."Last Direct Cost" := LibraryRandom.RandDec(100, 2);
        Item.Modify();
        // [GIVEN] Asset, where "Price Type" 'Purchase'
        PriceAsset."Price Type" := "Price Type"::Purchase;
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        // [WHEN] Validate Item "Asset ID" as SystemId of 'I'
        PriceAsset.Validate("Asset ID", Item.SystemId);
        // [THEN] Asset, where "Unit Price" is 'X'
        PriceAsset.TestField("Unit Price", Item."Last Direct Cost");
    end;

    [Test]
    procedure T012_UnitPriceForResourceSale()
    var
        Resource: Record Resource;
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Resource] [Sale]
        Initialize();
        // [GIVEN] Resource 'R', where "Unit Price" is 'X'
        LibraryResource.CreateResource(Resource, '');
        Resource."Unit Price" := LibraryRandom.RandDec(100, 2);
        Resource.Modify();
        // [GIVEN] Asset, where "Price Type" 'Sale'
        PriceAsset."Price Type" := "Price Type"::Sale;
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        // [WHEN] Validate Resource "Asset ID" as SystemId of 'R'
        PriceAsset.Validate("Asset ID", Resource.SystemId);
        // [THEN] Asset, where "Unit Price" is 'X'
        PriceAsset.TestField("Unit Price", Resource."Unit Price");
    end;

    [Test]
    procedure T013_UnitPriceForResourcePurchase()
    var
        Resource: Record Resource;
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Resource] [Purchase]
        Initialize();
        // [GIVEN] Resource 'R', where "Direct Unit Cost" is 'X', "Unit Cost" is 'Y'
        LibraryResource.CreateResource(Resource, '');
        Resource."Direct Unit Cost" := LibraryRandom.RandDec(100, 2);
        Resource."Unit Cost" := LibraryRandom.RandDec(100, 2);
        Resource.Modify();
        // [GIVEN] Asset, where "Price Type" 'Purchase'
        PriceAsset."Price Type" := "Price Type"::Purchase;
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        // [WHEN] Validate Resource "Asset ID" as SystemId of 'R'
        PriceAsset.Validate("Asset ID", Resource.SystemId);
        // [THEN] Asset, where "Unit Price" is 'X', "Unit Price 2" is 'Y'
        PriceAsset.TestField("Unit Price", Resource."Direct Unit Cost");
        PriceAsset.TestField("Unit Price 2", Resource."Unit Cost");
    end;

    [Test]
    procedure T020_DescriptionForItem()
    var
        Item: Record Item;
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Item]
        Initialize();
        // [GIVEN] Item 'I', where Description is 'X'
        LibraryInventory.CreateItem(Item);
        Item.Description := LibraryRandom.RandText(MaxStrLen(Item.Description));
        Item.Modify();
        // [WHEN] Validate Item "Asset No." as 'I'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.TestField("Table Id", Database::Item);
        PriceAsset.Validate("Asset No.", Item."No.");
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, Item.Description);
    end;

    [Test]
    procedure T021_DescriptionForItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Item Variant]
        Initialize();
        // [GIVEN] Item Variant 'IV', where Description is 'X'
        LibraryInventory.CreateItem(Item);
        Item.Description := LibraryRandom.RandText(MaxStrLen(Item.Description));
        Item.Modify();
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        ItemVariant.Description := LibraryRandom.RandText(MaxStrLen(ItemVariant.Description));
        ItemVariant.Modify();

        // [WHEN] Validate Item "Asset No." as 'I', "Variant Code" as 'IV'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.Validate("Asset No.", Item."No.");
        PriceAsset.TestField("Table Id", Database::Item);
        PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Asset, where Description is 'X', "Table Id" is 'Item Variant'
        PriceAsset.TestField(Description, ItemVariant.Description);
        PriceAsset.TestField("Table Id", Database::"Item Variant");
    end;

    [Test]
    procedure T022_DescriptionForResource()
    var
        PriceAsset: Record "Price Asset";
        Resource: Record Resource;
    begin
        // [FEATURE] [Resource]
        Initialize();
        // [GIVEN] Resource 'R', where Description is 'X'
        LibraryResource.CreateResource(Resource, '');
        Resource.Name := LibraryRandom.RandText(MaxStrLen(Resource.Name));
        Resource.Modify();
        // [WHEN] Validate Resource "Asset No." as 'R'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset.TestField("Table Id", Database::Resource);
        PriceAsset.Validate("Asset No.", Resource."No.");
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, Resource.Name);
    end;

    [Test]
    procedure T023_DescriptionForResourceGroup()
    var
        PriceAsset: Record "Price Asset";
        ResourceGroup: Record "Resource Group";
    begin
        // [FEATURE] [Resource Group]
        Initialize();
        // [GIVEN] ResourceGroup 'RG', where Description is 'X'
        LibraryResource.CreateResourceGroup(ResourceGroup);
        ResourceGroup.Name := LibraryRandom.RandText(MaxStrLen(ResourceGroup.Name));
        ResourceGroup.Modify();
        // [WHEN] Validate ResourceGroup "Asset No." as 'RG'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");
        PriceAsset.TestField("Table Id", Database::"Resource Group");
        PriceAsset.Validate("Asset No.", ResourceGroup."No.");
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, ResourceGroup.Name);
    end;

    [Test]
    procedure T024_DescriptionForItemDiscountGroup()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Item Discount Group]
        Initialize();
        // [GIVEN] Item 'IDG', where Description is 'X'
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        ItemDiscountGroup.Description := LibraryRandom.RandText(MaxStrLen(ItemDiscountGroup.Description));
        ItemDiscountGroup.Modify();
        // [WHEN] Validate ItemDiscountGroup "Asset No." as 'IGD'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Item Discount Group");
        PriceAsset.TestField("Table Id", Database::"Item Discount Group");
        PriceAsset.Validate("Asset No.", ItemDiscountGroup.Code);
        // [THEN] Asset, where Description is 'X', "Amount Type"::Discount
        PriceAsset.TestField(Description, ItemDiscountGroup.Description);
        PriceAsset.TestField("Amount Type", "Price Amount Type"::Discount);
    end;

    [Test]
    procedure T025_DescriptionForServiceCost()
    var
        PriceAsset: Record "Price Asset";
        ServiceCost: Record "Service Cost";
    begin
        // [FEATURE] [Service Cost]
        Initialize();
        // [GIVEN] ServiceCost 'SC', where Description is 'X'
        LibraryService.CreateServiceCost(ServiceCost);
        ServiceCost.Description := LibraryRandom.RandText(MaxStrLen(ServiceCost.Description));
        ServiceCost.Modify();
        // [WHEN] Validate ServiceCost "Asset No." as 'SC'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Service Cost");
        PriceAsset.TestField("Table Id", Database::"Service Cost");
        PriceAsset.Validate("Asset No.", ServiceCost.Code);
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, ServiceCost.Description);
    end;

    [Test]
    procedure T026_DescriptionForGLAccount()
    var
        GLAccount: Record "G/L Account";
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [G/L Account]
        Initialize();
        // [GIVEN] GLAccount 'A', where Description is 'X'
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Name := LibraryRandom.RandText(MaxStrLen(GLAccount.Name));
        GLAccount.Modify();
        // [WHEN] Validate GLAccount "Asset No." as 'A'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"G/L Account");
        PriceAsset.TestField("Table Id", Database::"G/L Account");
        PriceAsset.Validate("Asset No.", GLAccount."No.");
        // [THEN] Asset, where Description is 'X'
        PriceAsset.TestField(Description, GLAccount.Name);
    end;

    [Test]
    procedure T027_DescriptionBlankOnBlankProduct()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [Description]
        Initialize();
        // [GIVEN] Asset, where Item 'I', Description is 'X'
        PriceAsset."Asset Type" := PriceAsset."Asset Type"::Item;
        PriceAsset."Asset No." := LibraryUtility.GenerateGUID();
        PriceAsset.Description := LibraryUtility.GenerateGUID();
        // [WHEN] Validate Item "Asset No." as <blank>
        PriceAsset.Validate("Asset No.", '');
        // [THEN] Asset, where Description is <blank>
        PriceAsset.TestField(Description, '');
    end;

    [Test]
    procedure T030_WorkTypeCodeNotAllowedForItem()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Work Type Code" must not be filled for product type 'Item'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceAsset.Validate("Work Type Code", GetWorkTypeCode(''));
        // [THEN] Error message: 'Work Type Code must be empty'
        Assert.ExpectedTestFieldError(PriceAsset.FieldCaption("Asset Type"), Format(PriceAsset."Asset Type"::Resource));
    end;

    [Test]
    procedure T031_WorkTypeCodeNotAllowedForGLAccount()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Work Type Code" must not be filled for product type 'G/L Account'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'G/L Account' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"G/L Account");
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceAsset.Validate("Work Type Code", GetWorkTypeCode(''));
        // [THEN] Error message: 'Work Type Code must be empty'
        Assert.ExpectedTestFieldError(PriceAsset.FieldCaption("Asset Type"), Format(PriceAsset."Asset Type"::Resource));
    end;

    [Test]
    procedure T032_WorkTypeCodeNotAllowedForItemDiscountGroup()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Work Type Code" must not be filled for product type 'Item Discount Group'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item Discount Group' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Item Discount Group");
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceAsset.Validate("Work Type Code", GetWorkTypeCode(''));
        // [THEN] Error message: 'Work Type Code must be empty'
        Assert.ExpectedTestFieldError(PriceAsset.FieldCaption("Asset Type"), Format(PriceAsset."Asset Type"::Resource));
    end;

    [Test]
    procedure T033_WorkTypeCodeNotAllowedForServiceCost()
    var
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Work Type Code" must not be filled for product type 'Service Cost'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Service Cost' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Service Cost");
        // [WHEN] Validate "Work Type Code" with a valid code
        asserterror PriceAsset.Validate("Work Type Code", GetWorkTypeCode(''));
        // [THEN] Error message: 'Work Type Code must be empty'
        Assert.ExpectedTestFieldError(PriceAsset.FieldCaption("Asset Type"), Format(PriceAsset."Asset Type"::Resource));
    end;

    [Test]
    procedure T034_WorkTypeCodeAllowedForResourceGroup()
    var
        PriceAsset: Record "Price Asset";
        ResourceGroup: Record "Resource Group";
        WorkType: Record "Work Type";
    begin
        // [SCENARIO] "Work Type Code" can be filled for product type 'Resource Group'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Resource Group' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");
        LibraryResource.CreateResourceGroup(ResourceGroup);
        PriceAsset.Validate("Asset No.", ResourceGroup."No.");
        // [GIVEN] Work Type 'WT', where "Unit Of Measure" is 'WT-UOM' 
        WorkType.Get(GetWorkTypeCode(''));

        // [WHEN] Validate "Work Type Code" with a valid code 'WT'
        PriceAsset.Validate("Work Type Code", WorkType.Code);

        // [THEN] Asset, where 'Work Type Code' is 'WT', "Unit Of Measure" is 'WT-UOM' 
        PriceAsset.TestField("Work Type Code", WorkType.Code);
        PriceAsset.TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
    end;

    [Test]
    procedure T035_WorkTypeCodeAllowedForResource()
    var
        PriceAsset: Record "Price Asset";
        Resource: Record Resource;
        WorkType: Record "Work Type";
    begin
        // [FEATURE] [Resource]
        // [SCENARIO] "Work Type Code" set for product type 'Resource' updates "Unit Of Measure"
        Initialize();
        // [GIVEN] Resource 'R', where "Base Unit Of Measure" is 'R-UOM' 
        LibraryResource.CreateResource(Resource, '');
        // [GIVEN] Price Asset, where "Asset Type" is 'Resource', "Asset No." is 'R'
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset.Validate("Asset No.", Resource."No.");
        // [GIVEN] Asset, where "Unit Of Measure" is 'R-UOM' 
        PriceAsset.TestField("Unit of Measure Code", Resource."Base Unit of Measure");

        // [GIVEN] Work Type 'WT', where "Unit Of Measure" is 'WT-UOM' 
        WorkType.Get(GetWorkTypeCode(Resource."No."));

        // [WHEN] Validate "Work Type Code" with a valid code 'WT'
        PriceAsset.Validate("Work Type Code", WorkType.Code);

        // [THEN] Asset, where 'Work Type Code' is 'WT', "Unit Of Measure" is 'WT-UOM' 
        PriceAsset.TestField("Work Type Code", WorkType.Code);
        PriceAsset.TestField("Unit of Measure Code", WorkType."Unit of Measure Code");
    end;

    [Test]
    procedure T040_VariantCodeAllowedForItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" can be filled for product type 'Item'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item', "Asset No." is 'I' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        LibraryInventory.CreateItem(Item);
        PriceAsset.Validate("Asset No.", Item."No.");
        // [WHEN] Validate "Variant Code" with a valid code 'V'
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] "Variant Code" is 'V'
        PriceAsset.TestField("Variant Code", ItemVariant.Code);
    end;

    [Test]
    procedure T041_VariantCodeNotAllowedForItemDiscGroup()
    var
        ItemDiscountGroup: Record "Item Discount Group";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'Item Discount Group'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item Discount Group', "Asset No." is 'IDG' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Item Discount Group");
        LibraryERM.CreateItemDiscountGroup(ItemDiscountGroup);
        PriceAsset.Validate("Asset No.", ItemDiscountGroup.Code);
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedTestFieldError(PriceAsset.FieldCaption("Asset Type"), Format(PriceAsset."Asset Type"::Item));
    end;

    [Test]
    procedure T042_VariantCodeNotAllowedForGLAccount()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'G/L Account'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'G/L Account', "Asset No." is 'A' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"G/L Account");
        PriceAsset.Validate("Asset No.", LibraryERM.CreateGLAccountNo());
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedTestFieldError(PriceAsset.FieldCaption("Asset Type"), Format(PriceAsset."Asset Type"::Item));
    end;

    [Test]
    procedure T043_VariantCodeNotAllowedForResource()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'Resource'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Resource', "Asset No." is 'R' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset.Validate("Asset No.", LibraryResource.CreateResourceNo());
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedTestFieldError(PriceAsset.FieldCaption("Asset Type"), Format(PriceAsset."Asset Type"::Item));
    end;

    [Test]
    procedure T044_VariantCodeNotAllowedForResourceGroup()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
        ResourceGroup: Record "Resource Group";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'Resource Group'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Resource Group', "Asset No." is 'RG' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");
        LibraryResource.CreateResourceGroup(ResourceGroup);
        PriceAsset.Validate("Asset No.", ResourceGroup."No.");
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedTestFieldError(PriceAsset.FieldCaption("Asset Type"), Format(PriceAsset."Asset Type"::Item));
    end;

    [Test]
    procedure T045_VariantCodeNotAllowedForServiceCost()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
        ServiceCost: Record "Service Cost";
    begin
        // [SCENARIO] "Variant Code" must not be filled for product type 'Service Cost'
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Service Cost', "Asset No." is 'SC' 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Service Cost");
        LibraryService.CreateServiceCost(ServiceCost);
        PriceAsset.Validate("Asset No.", ServiceCost.Code);
        // [WHEN] Validate "Variant Code" with a valid code
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Variant Code must be empty'
        Assert.ExpectedTestFieldError(PriceAsset.FieldCaption("Asset Type"), Format(PriceAsset."Asset Type"::Item));
    end;

    [Test]
    procedure T046_VariantCodeNoAllowedForBlankItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
    begin
        // [SCENARIO] "Variant Code" cannot be filled for product type 'Item', but blank "Asset No."
        Initialize();
        // [GIVEN] Price Asset, where "Asset Type" is 'Item', "Asset No." is <blank> 
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.Validate("Asset No.", '');
        // [WHEN] Validate "Variant Code" with a valid code 'V'
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        asserterror PriceAsset.Validate("Variant Code", ItemVariant.Code);
        // [THEN] Error message: 'Asset No. must have a value.'
        Assert.ExpectedError(AssetNoMustHaveValueErr);
    end;

    [Test]
    [HandlerFunctions('ItemVariantsPageHandler')]
    procedure VariantLookupShowsCorrespondingRecords()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        PriceAsset: Record "Price Asset";
        PriceAssetItem: Codeunit "Price Asset - Item";
    begin
        // [SCENARIO 384368] The page Item Variants shows corresponding records for Item with No. of max length
        Initialize();

        // [GIVEN] Item ("I") with No. = 'MAXLENGHTNAME_CODE20'
        LibraryInventory.CreateItem(Item);
        Item.Rename(LibraryUtility.GenerateRandomCode20(Item.FieldNo("No."), Database::Item));

        // [GIVEN] Item Variant ("IV") for item "I"
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Price Asset for item "I"
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.Validate("Asset No.", Item."No.");
        LibraryVariableStorage.Enqueue(ItemVariant.Code);

        // [WHEN] Open Lookup for Item Variants
        PriceAssetItem.IsLookupVariantOK(PriceAsset);

        // [THEN] Item Variant shows item variant "IV" 
        // Validation is in ItemVariantsPageHandler

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure ItemUOMBeforeProductPreservesNondefaultUnit()
    var
        Item: Record Item;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] An item accepts a nondefault unit before the product number is supplied.
        Initialize();

        // [GIVEN] Item "I" has an additional unit "U" distinct from its default.
        UnitOfMeasureCode := CreateItemWithAlternateUOM(Item);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);

        // [WHEN] Unit "U" is validated before item "I".
        PriceAsset.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PriceAsset.Validate("Asset No.", Item."No.");

        // [THEN] The resolved item retains unit "U".
        VerifyAssetUnit(PriceAsset, Item."No.", UnitOfMeasureCode);
    end;

    [Test]
    procedure ResourceUOMBeforeProductPreservesNondefaultUnit()
    var
        Resource: Record Resource;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A resource accepts a nondefault unit before the product number is supplied.
        Initialize();

        // [GIVEN] Resource "R" has an additional unit "U".
        LibraryResource.CreateResource(Resource, '');
        UnitOfMeasureCode := CreateResourceUOM(Resource."No.");
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);

        // [WHEN] Unit "U" is validated before resource "R".
        PriceAsset.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PriceAsset.Validate("Asset No.", Resource."No.");

        // [THEN] The resolved resource retains unit "U", not its base unit.
        VerifyAssetUnit(PriceAsset, Resource."No.", UnitOfMeasureCode);
    end;

    [Test]
    procedure ItemProductPreservesAssignedNondefaultUOM()
    var
        Item: Record Item;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] First product validation does not overwrite an already supplied item unit.
        Initialize();

        // [GIVEN] Item "I" has additional unit "U", supplied before asset initialization.
        UnitOfMeasureCode := CreateItemWithAlternateUOM(Item);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset."Unit of Measure Code" := UnitOfMeasureCode;

        // [WHEN] Item "I" is assigned for the first time.
        PriceAsset.Validate("Asset No.", Item."No.");

        // [THEN] Initialization preserves the actual supplied unit.
        VerifyAssetUnit(PriceAsset, Item."No.", UnitOfMeasureCode);
    end;

    [Test]
    procedure ResourceProductPreservesAssignedNondefaultUOM()
    var
        Resource: Record Resource;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] First product validation does not overwrite an already supplied resource unit.
        Initialize();

        // [GIVEN] Resource "R" has additional unit "U", supplied before asset initialization.
        LibraryResource.CreateResource(Resource, '');
        UnitOfMeasureCode := CreateResourceUOM(Resource."No.");
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset."Unit of Measure Code" := UnitOfMeasureCode;

        // [WHEN] Resource "R" is assigned for the first time.
        PriceAsset.Validate("Asset No.", Resource."No.");

        // [THEN] Initialization preserves the actual supplied unit.
        VerifyAssetUnit(PriceAsset, Resource."No.", UnitOfMeasureCode);
    end;

    [Test]
    procedure ItemRejectsDeferredUOMForAnotherItem()
    var
        Item: Record Item;
        OtherItem: Record Item;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A deferred unit must belong to the item eventually selected.
        Initialize();

        // [GIVEN] Unit "U" belongs to item "J", but not item "I".
        LibraryInventory.CreateItem(Item);
        UnitOfMeasureCode := CreateItemWithAlternateUOM(OtherItem);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [WHEN] Item "I" is supplied after unit "U".
        asserterror PriceAsset.Validate("Asset No.", Item."No.");

        // [THEN] The missing item-specific unit is rejected, rather than defaulted.
        VerifyMissingUnitError('Item Unit of Measure', UnitOfMeasureCode);
    end;

    [Test]
    procedure ResourceRejectsDeferredUOMForAnotherResource()
    var
        Resource: Record Resource;
        OtherResource: Record Resource;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A deferred unit must belong to the resource eventually selected.
        Initialize();

        // [GIVEN] Unit "U" belongs to resource "S", but not resource "R".
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateResource(OtherResource, '');
        UnitOfMeasureCode := CreateResourceUOM(OtherResource."No.");
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [WHEN] Resource "R" is supplied after unit "U".
        asserterror PriceAsset.Validate("Asset No.", Resource."No.");

        // [THEN] The missing resource-specific unit is rejected, rather than defaulted.
        VerifyMissingUnitError('Resource Unit of Measure', UnitOfMeasureCode);
    end;

    [Test]
    procedure ResourceGroupAcceptsGlobalUOMBeforeProduct()
    var
        ResourceGroup: Record "Resource Group";
        UnitOfMeasure: Record "Unit of Measure";
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Resource groups use global units without requiring a resource-specific relation.
        Initialize();

        // [GIVEN] Resource group "G" and global unit "U" exist without any resource unit relation.
        LibraryResource.CreateResourceGroup(ResourceGroup);
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");

        // [WHEN] Unit "U" is supplied before group "G".
        PriceAsset.Validate("Unit of Measure Code", UnitOfMeasure.Code);
        PriceAsset.Validate("Asset No.", ResourceGroup."No.");

        // [THEN] The group retains the global unit.
        VerifyAssetUnit(PriceAsset, ResourceGroup."No.", UnitOfMeasure.Code);
    end;

    [Test]
    procedure ResourceGroupRejectsMissingGlobalUOMBeforeProduct()
    var
        UnitOfMeasure: Record "Unit of Measure";
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A resource group validates global unit existence even without a product number.
        Initialize();

        // [GIVEN] Unit "U" no longer exists and the resource group number is blank.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        UnitOfMeasure.Delete(true);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");

        // [WHEN] Missing unit "U" is supplied.
        asserterror PriceAsset.Validate("Unit of Measure Code", UnitOfMeasure.Code);

        // [THEN] The error concerns the missing global unit, not the blank product number.
        VerifyMissingUnitError('Unit of Measure', UnitOfMeasure.Code);
    end;

    [Test]
    procedure ItemProductFirstAcceptsNondefaultUOM()
    var
        Item: Record Item;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Product-first item validation continues to default and accept an alternate unit.
        Initialize();

        // [GIVEN] Item "I" has an additional unit "U".
        UnitOfMeasureCode := CreateItemWithAlternateUOM(Item);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.Validate("Asset No.", Item."No.");
        VerifyAssetUnit(PriceAsset, Item."No.", Item."Base Unit of Measure");

        // [WHEN] Unit "U" is supplied after item "I".
        PriceAsset.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [THEN] The alternate unit is accepted.
        VerifyAssetUnit(PriceAsset, Item."No.", UnitOfMeasureCode);
    end;

    [Test]
    procedure ResourceProductFirstAcceptsNondefaultUOM()
    var
        Resource: Record Resource;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Product-first resource validation continues to default and accept an alternate unit.
        Initialize();

        // [GIVEN] Resource "R" has an additional unit "U".
        LibraryResource.CreateResource(Resource, '');
        UnitOfMeasureCode := CreateResourceUOM(Resource."No.");
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset.Validate("Asset No.", Resource."No.");
        VerifyAssetUnit(PriceAsset, Resource."No.", Resource."Base Unit of Measure");

        // [WHEN] Unit "U" is supplied after resource "R".
        PriceAsset.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [THEN] The alternate unit is accepted.
        VerifyAssetUnit(PriceAsset, Resource."No.", UnitOfMeasureCode);
    end;

    [Test]
    procedure ItemProductChangeRestoresNewProductDefaultUOM()
    var
        Item: Record Item;
        OtherItem: Record Item;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Changing an existing item must not preserve the previous item's alternate unit.
        Initialize();

        // [GIVEN] Item "I" uses alternate unit "U" and item "J" has a different default.
        UnitOfMeasureCode := CreateItemWithAlternateUOM(Item);
        LibraryInventory.CreateItem(OtherItem);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);
        PriceAsset.Validate("Asset No.", Item."No.");
        PriceAsset.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [WHEN] The product changes to item "J".
        PriceAsset.Validate("Asset No.", OtherItem."No.");

        // [THEN] The new item's default replaces unit "U".
        VerifyAssetUnit(PriceAsset, OtherItem."No.", OtherItem."Base Unit of Measure");
    end;

    [Test]
    procedure ResourceProductChangeRestoresNewProductDefaultUOM()
    var
        Resource: Record Resource;
        OtherResource: Record Resource;
        PriceAsset: Record "Price Asset";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Changing a resource must not preserve the previous resource's alternate unit.
        Initialize();

        // [GIVEN] Resource "R" uses alternate unit "U" and resource "S" has a different default.
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateResource(OtherResource, '');
        UnitOfMeasureCode := CreateResourceUOM(Resource."No.");
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Resource);
        PriceAsset.Validate("Asset No.", Resource."No.");
        PriceAsset.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [WHEN] The product changes to resource "S".
        PriceAsset.Validate("Asset No.", OtherResource."No.");

        // [THEN] The new resource's default replaces unit "U".
        VerifyAssetUnit(PriceAsset, OtherResource."No.", OtherResource."Base Unit of Measure");
    end;

    [Test]
    procedure BlankAssetTypeRejectsUOMBeforeProduct()
    var
        PriceAsset: Record "Price Asset";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A blank asset type still rejects a nonblank unit before a product is supplied.
        Initialize();

        // [GIVEN] The asset type is blank and global unit "U" exists.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::" ");

        // [WHEN] Unit "U" is supplied.
        asserterror PriceAsset.Validate("Unit of Measure Code", UnitOfMeasure.Code);

        // [THEN] Unsupported types remain rejected.
        VerifyUnsupportedUnitError();
    end;

    [Test]
    procedure GLAccountRejectsUOMBeforeProduct()
    var
        PriceAsset: Record "Price Asset";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] G/L accounts still reject a unit before a product is supplied.
        Initialize();

        // [GIVEN] The asset type is G/L Account and global unit "U" exists.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"G/L Account");

        // [WHEN] Unit "U" is supplied.
        asserterror PriceAsset.Validate("Unit of Measure Code", UnitOfMeasure.Code);

        // [THEN] Unsupported types remain rejected.
        VerifyUnsupportedUnitError();
    end;

    [Test]
    procedure ItemDiscountGroupRejectsUOMBeforeProduct()
    var
        PriceAsset: Record "Price Asset";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Item discount groups still reject a unit before a product is supplied.
        Initialize();

        // [GIVEN] The asset type is Item Discount Group and global unit "U" exists.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Item Discount Group");

        // [WHEN] Unit "U" is supplied.
        asserterror PriceAsset.Validate("Unit of Measure Code", UnitOfMeasure.Code);

        // [THEN] Unsupported types remain rejected.
        VerifyUnsupportedUnitError();
    end;

    [Test]
    procedure ServiceCostRejectsUOMBeforeProduct()
    var
        PriceAsset: Record "Price Asset";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Service costs still reject a unit before a product is supplied.
        Initialize();

        // [GIVEN] The asset type is Service Cost and global unit "U" exists.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Service Cost");

        // [WHEN] Unit "U" is supplied.
        asserterror PriceAsset.Validate("Unit of Measure Code", UnitOfMeasure.Code);

        // [THEN] Unsupported types remain rejected.
        VerifyUnsupportedUnitError();
    end;

    [Test]
    procedure BlankUOMBeforeItemUsesProductDefault()
    var
        Item: Record Item;
        PriceAsset: Record "Price Asset";
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A blank deferred unit does not suppress normal item defaulting.
        Initialize();

        // [GIVEN] Item "I" exists and no product has been supplied.
        LibraryInventory.CreateItem(Item);
        PriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::Item);

        // [WHEN] A blank unit is validated before item "I".
        PriceAsset.Validate("Unit of Measure Code", '');
        PriceAsset.Validate("Asset No.", Item."No.");

        // [THEN] The item's default unit is used.
        VerifyAssetUnit(PriceAsset, Item."No.", Item."Base Unit of Measure");
    end;

    [Test]
    procedure PriceLineItemUOMBeforeProductPreservesUnit()
    var
        Item: Record Item;
        PriceListLine: Record "Price List Line";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Price List Line preserves a nondefault item unit entered before Product No.
        Initialize();

        // [GIVEN] A draft item line and item "I" with alternate unit "U".
        UnitOfMeasureCode := CreateItemWithAlternateUOM(Item);
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);

        // [WHEN] Unit "U" is validated before the public Product No. field.
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PriceListLine.Validate("Product No.", Item."No.");

        // [THEN] The product and both unit fields retain the supplied values.
        VerifyPriceLineUnit(PriceListLine, Item."No.", UnitOfMeasureCode);
    end;

    [Test]
    procedure PriceLineResourceUOMBeforeProductPreservesUnit()
    var
        Resource: Record Resource;
        PriceListLine: Record "Price List Line";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Price List Line preserves a nondefault resource unit entered before Product No.
        Initialize();

        // [GIVEN] A draft resource line and resource "R" with alternate unit "U".
        LibraryResource.CreateResource(Resource, '');
        UnitOfMeasureCode := CreateResourceUOM(Resource."No.");
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);

        // [WHEN] Unit "U" is validated before the public Product No. field.
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PriceListLine.Validate("Product No.", Resource."No.");

        // [THEN] The product and both unit fields retain the supplied values.
        VerifyPriceLineUnit(PriceListLine, Resource."No.", UnitOfMeasureCode);
    end;

    [Test]
    procedure PriceLineRejectsDeferredUOMForAnotherItem()
    var
        Item: Record Item;
        OtherItem: Record Item;
        PriceListLine: Record "Price List Line";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Price List Line rejects an incompatible deferred unit when Product No. is set.
        Initialize();

        // [GIVEN] A draft item line has a unit "U" belonging to "J", not item "I".
        LibraryInventory.CreateItem(Item);
        UnitOfMeasureCode := CreateItemWithAlternateUOM(OtherItem);
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [WHEN] The public Product No. field is set to item "I".
        asserterror PriceListLine.Validate("Product No.", Item."No.");

        // [THEN] The item-specific unit relation is enforced.
        VerifyMissingUnitError('Item Unit of Measure', UnitOfMeasureCode);
    end;

    [Test]
    procedure PriceLineItemChangeUsesNewProductDefaultUOM()
    var
        Item: Record Item;
        OtherItem: Record Item;
        PriceListLine: Record "Price List Line";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Price List Line product changes retain normal defaulting through CopyRecTo.
        Initialize();

        // [GIVEN] A line for item "I" uses alternate unit "U" and item "J" exists.
        UnitOfMeasureCode := CreateItemWithAlternateUOM(Item);
        LibraryInventory.CreateItem(OtherItem);
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Product No.", Item."No.");
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [WHEN] The public Product No. field changes to item "J".
        PriceListLine.Validate("Product No.", OtherItem."No.");

        // [THEN] The new product's default replaces the old alternate unit in both fields.
        VerifyPriceLineUnit(PriceListLine, OtherItem."No.", OtherItem."Base Unit of Measure");
    end;

    [Test]
    procedure PriceLineResourceChangeUsesNewProductDefaultUOM()
    var
        Resource: Record Resource;
        OtherResource: Record Resource;
        PriceListLine: Record "Price List Line";
        UnitOfMeasureCode: Code[10];
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] Price List Line resource changes retain normal defaulting through CopyRecTo.
        Initialize();

        // [GIVEN] A line for resource "R" uses alternate unit "U" and resource "S" exists.
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateResource(OtherResource, '');
        UnitOfMeasureCode := CreateResourceUOM(Resource."No.");
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
        PriceListLine.Validate("Product No.", Resource."No.");
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasureCode);

        // [WHEN] The public Product No. field changes to resource "S".
        PriceListLine.Validate("Product No.", OtherResource."No.");

        // [THEN] The new resource's default replaces the old alternate unit in both fields.
        VerifyPriceLineUnit(PriceListLine, OtherResource."No.", OtherResource."Base Unit of Measure");
    end;

    [Test]
    procedure NewSalesItemLinePreservesUOMAndDefaultsOnChange()
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A new sales item line preserves a deferred unit until its product changes.
        Initialize();
        VerifyNewItemLineUnitAndProductChange("Price Type"::Sale);
    end;

    [Test]
    procedure NewPurchaseItemLinePreservesUOMAndDefaultsOnChange()
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A new purchase item line preserves a deferred unit until its product changes.
        Initialize();
        VerifyNewItemLineUnitAndProductChange("Price Type"::Purchase);
    end;

    [Test]
    procedure NewSalesResourceLinePreservesUOMAndDefaultsOnChange()
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A new sales resource line preserves a deferred unit until its product changes.
        Initialize();
        VerifyNewResourceLineUnitAndProductChange("Price Type"::Sale);
    end;

    [Test]
    procedure NewPurchaseResourceLinePreservesUOMAndDefaultsOnChange()
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A new purchase resource line preserves a deferred unit until its product changes.
        Initialize();
        VerifyNewResourceLineUnitAndProductChange("Price Type"::Purchase);
    end;

    [Test]
    procedure NewSalesItemLineRejectsIncompatibleDeferredUOM()
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A new sales item line rejects a deferred unit belonging to another item.
        Initialize();
        VerifyNewItemLineRejectsDeferredUnit("Price Type"::Sale);
    end;

    [Test]
    procedure NewPurchaseItemLineRejectsIncompatibleDeferredUOM()
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A new purchase item line rejects a deferred unit belonging to another item.
        Initialize();
        VerifyNewItemLineRejectsDeferredUnit("Price Type"::Purchase);
    end;

    [Test]
    procedure NewSalesResourceLineRejectsIncompatibleDeferredUOM()
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A new sales resource line rejects a deferred unit belonging to another resource.
        Initialize();
        VerifyNewResourceLineRejectsDeferredUnit("Price Type"::Sale);
    end;

    [Test]
    procedure NewPurchaseResourceLineRejectsIncompatibleDeferredUOM()
    begin
        // [FEATURE] [AI test 0.3]
        // [SCENARIO] A new purchase resource line rejects a deferred unit belonging to another resource.
        Initialize();
        VerifyNewResourceLineRejectsDeferredUnit("Price Type"::Purchase);
    end;

    local procedure VerifyNewItemLineUnitAndProductChange(PriceType: Enum "Price Type")
    var
        Item: Record Item;
        OtherItem: Record Item;
        PriceListLine: Record "Price List Line";
        UnitOfMeasureCode: Code[10];
    begin
        UnitOfMeasureCode := CreateItemWithAlternateUOM(Item);
        LibraryInventory.CreateItem(OtherItem);
        PriceListLine.SetNewRecord(true);
        PriceListLine."Price Type" := PriceType;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasureCode);

        PriceListLine.Validate("Product No.", Item."No.");

        VerifyPriceLineUnit(PriceListLine, Item."No.", UnitOfMeasureCode);
        Assert.AreEqual(Item.SystemId, PriceListLine."Asset ID", 'The first product must be resolved.');

        PriceListLine.Validate("Product No.", OtherItem."No.");

        VerifyPriceLineUnit(PriceListLine, OtherItem."No.", OtherItem."Base Unit of Measure");
        Assert.AreEqual(OtherItem.SystemId, PriceListLine."Asset ID", 'The replacement product must be resolved.');
    end;

    local procedure VerifyNewResourceLineUnitAndProductChange(PriceType: Enum "Price Type")
    var
        Resource: Record Resource;
        OtherResource: Record Resource;
        PriceListLine: Record "Price List Line";
        UnitOfMeasureCode: Code[10];
    begin
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateResource(OtherResource, '');
        UnitOfMeasureCode := CreateResourceUOM(Resource."No.");
        Assert.AreNotEqual(Resource."Base Unit of Measure", UnitOfMeasureCode, 'The test requires a nondefault unit.');
        PriceListLine.SetNewRecord(true);
        PriceListLine."Price Type" := PriceType;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasureCode);

        PriceListLine.Validate("Product No.", Resource."No.");

        VerifyPriceLineUnit(PriceListLine, Resource."No.", UnitOfMeasureCode);
        Assert.AreEqual(Resource.SystemId, PriceListLine."Asset ID", 'The first product must be resolved.');

        PriceListLine.Validate("Product No.", OtherResource."No.");

        VerifyPriceLineUnit(PriceListLine, OtherResource."No.", OtherResource."Base Unit of Measure");
        Assert.AreEqual(OtherResource.SystemId, PriceListLine."Asset ID", 'The replacement product must be resolved.');
    end;

    local procedure VerifyNewItemLineRejectsDeferredUnit(PriceType: Enum "Price Type")
    var
        Item: Record Item;
        OtherItem: Record Item;
        PriceListLine: Record "Price List Line";
        UnitOfMeasureCode: Code[10];
    begin
        LibraryInventory.CreateItem(Item);
        UnitOfMeasureCode := CreateItemWithAlternateUOM(OtherItem);
        PriceListLine.SetNewRecord(true);
        PriceListLine."Price Type" := PriceType;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Item);
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasureCode);

        asserterror PriceListLine.Validate("Product No.", Item."No.");

        VerifyMissingUnitError('Item Unit of Measure', UnitOfMeasureCode);
    end;

    local procedure VerifyNewResourceLineRejectsDeferredUnit(PriceType: Enum "Price Type")
    var
        Resource: Record Resource;
        OtherResource: Record Resource;
        PriceListLine: Record "Price List Line";
        UnitOfMeasureCode: Code[10];
    begin
        LibraryResource.CreateResource(Resource, '');
        LibraryResource.CreateResource(OtherResource, '');
        UnitOfMeasureCode := CreateResourceUOM(OtherResource."No.");
        PriceListLine.SetNewRecord(true);
        PriceListLine."Price Type" := PriceType;
        PriceListLine.Validate("Asset Type", PriceListLine."Asset Type"::Resource);
        PriceListLine.Validate("Unit of Measure Code", UnitOfMeasureCode);

        asserterror PriceListLine.Validate("Product No.", Resource."No.");

        VerifyMissingUnitError('Resource Unit of Measure', UnitOfMeasureCode);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Price Asset UT");
        LibraryVariableStorage.Clear();

        if isInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Price Asset UT");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Price Asset UT");
    end;


    local procedure GetWorkTypeCode(ResourceNo: Code[20]): Code[10]
    var
        WorkType: Record "Work Type";
    begin
        LibraryResource.CreateWorkType(WorkType);
        if ResourceNo <> '' then
            WorkType."Unit of Measure Code" := CreateResourceUOM(ResourceNo);
        exit(WorkType.Code);
    end;

    local procedure CreateResourceUOM(ResourceNo: Code[20]): Code[10]
    var
        ResourceUnitofMeasure: Record "Resource Unit of Measure";
        UnitofMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitofMeasure);
        LibraryResource.CreateResourceUnitOfMeasure(
            ResourceUnitofMeasure, ResourceNo, UnitofMeasure.Code, 2.0);
        exit(UnitofMeasure.Code);
    end;

    local procedure CreateItemWithAlternateUOM(var Item: Record Item): Code[10]
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", 2);
        Assert.AreNotEqual(Item."Base Unit of Measure", ItemUnitOfMeasure.Code, 'The test requires a nondefault unit.');
        exit(ItemUnitOfMeasure.Code);
    end;

    local procedure VerifyAssetUnit(PriceAsset: Record "Price Asset"; AssetNo: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        Assert.AreEqual(AssetNo, PriceAsset."Asset No.", 'The selected product must be retained.');
        Assert.AreEqual(UnitOfMeasureCode, PriceAsset."Unit of Measure Code", 'The product must use the expected unit.');
    end;

    local procedure VerifyPriceLineUnit(PriceListLine: Record "Price List Line"; ProductNo: Code[20]; UnitOfMeasureCode: Code[10])
    begin
        Assert.AreEqual(ProductNo, PriceListLine."Product No.", 'The public product number must match the selection.');
        Assert.AreEqual(ProductNo, PriceListLine."Asset No.", 'The asset number must match the selection.');
        Assert.AreEqual(UnitOfMeasureCode, PriceListLine."Unit of Measure Code", 'The supplied unit must be retained.');
        Assert.AreEqual(UnitOfMeasureCode, PriceListLine."Unit of Measure Code Lookup", 'The lookup unit must remain synchronized.');
    end;

    local procedure VerifyMissingUnitError(TableName: Text; UnitOfMeasureCode: Code[10])
    begin
        Assert.ExpectedError(TableName + ' does not exist.');
        Assert.ExpectedError(UnitOfMeasureCode);
        Assert.ExpectedErrorCode('DB:RecordNotFound');
    end;

    local procedure VerifyUnsupportedUnitError()
    begin
        Assert.ExpectedError('Product Type must be equal to Item or Resource.');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmTrueHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemVariantsPageHandler(var ItemVariants: TestPage "Item Variants")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ItemVariants.Code.Value, 'Wrong Item Variant Code.');
    end;

}