codeunit 134462 "ERM Copy Item"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Copy Item]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryCosting: Codeunit "Library - Costing";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryERM: Codeunit "Library - ERM";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryResource: Codeunit "Library - Resource";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryNoSeries: Codeunit "Library - No. Series";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        IsInitialized: Boolean;
        TargetItemNoErr: Label 'Target item number %1 already exists.';
        NoOfRecordsMismatchErr: Label 'Number of target records does not match the number of source records';
        TargetItemNoTxt: Label 'Target Item No.';
        UnincrementableStringErr: Label 'The value in the %1 field must have a number so that we can assign the next number in the series.', Comment = '%1 = New Field Name';
        CustomerNameErr: Label 'Invalid Customer Name';
        CostAdjustedTrueErr: Label 'Cost is Adjusted should be TRUE for new copied item';

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLine()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        Comment: Text[80];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO] Copy item with comment lines
        Initialize();

        // [GIVEN] Item "I" with Comment Line
        Comment := CreateItemWithCommentLine(Item);

        // [WHEN] Run "Copy Item" report for item "I" with Comments = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Comments := true;
        CopyItemBuffer."Units of Measure" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Comment line copied
        VerifyItemGeneralInformation(CopyItemBuffer."Target Item No.", Item.Description);
        VerifyCommentLine(CopyItemBuffer."Target Item No.", Comment);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndTranslation()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        Comment: Text[80];
        Description: Text[50];
    begin
        // [FEATURE] [Comments]
        // [SCENARIO] Copy item with comment lines and item translation
        Initialize();

        // [GIVEN] Item "I" with Comment Line and Item Translation
        Comment := CreateItemWithCommentLine(Item);
        Description := CreateItemTranslation(Item."No.");

        // [WHEN] Run "Copy Item" report for item "I" with Comments = "Yes", "Item Translation" = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Comments := true;
        CopyItemBuffer.Translations := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Comment line and item translation copied
        VerifyItemGeneralInformation(CopyItemBuffer."Target Item No.", Item.Description);
        VerifyCommentLine(CopyItemBuffer."Target Item No.", Comment);
        VerifyItemTranslation(CopyItemBuffer."Target Item No.", Description);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndDefaultDimension()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        DefaultDimension: Record "Default Dimension";
        Comment: Text[80];
    begin
        // [FEATURE] [Comments] [Default Dimension]
        // [SCENARIO] Copy item with comment lines and default dimension
        Initialize();

        // [GIVEN] Item "I" with Comment Line and default dimension
        Comment := CreateItemWithCommentLine(Item);
        CreateDefaultDimensionForItem(DefaultDimension, Item."No.");

        // [WHEN] Run "Copy Item" report for item "I" with Comments = "Yes", Dimensions = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Comments := true;
        CopyItemBuffer.Dimensions := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Comment line and default dimensions copied
        VerifyItemGeneralInformation(CopyItemBuffer."Target Item No.", Item.Description);
        VerifyCommentLine(CopyItemBuffer."Target Item No.", Comment);
        VerifyDefaultDimension(DefaultDimension, CopyItemBuffer."Target Item No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemErrorAfterCreatingTargetItem()
    var
        Item: Record Item;
        Item2: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Item cannot be copeid if item with target item number already exists
        Initialize();

        // [GIVEN] Create items "I1" and "I2"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItem(Item2);
        CopyItemBuffer."Target Item No." := Item2."No.";
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);

        // [WHEN] Run copy item report with target item number "I2"
        asserterror CopyItem(Item."No.");

        // [THEN] Error "Target item I2 already exists"
        Assert.ExpectedError(StrSubstNo(TargetItemNoErr, Item2."No."));
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemErrorWithItemCommentLine()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
    begin
        // [FEATURE] [Comments]
        // [SCENARIO] Item cannot be copeid with same target item number twice
        Initialize();

        // [GIVEN] Create item "I1", copy it to item "I2"
        CreateItemWithCommentLine(Item);
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Comments := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [WHEN] Run copy item report with target item number "I2" again
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        asserterror CopyItem(Item."No.");

        // [THEN] Error "Target item I2 already exists"
        Assert.ExpectedError(StrSubstNo(TargetItemNoErr, CopyItemBuffer."Target Item No."));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndVariant()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        ItemVariant: Record "Item Variant";
        Comment: Text[80];
    begin
        // [FEATURE] [Comments] [Item Variant]
        // [SCENARIO] Copy item with comment lines and Item Variant
        Initialize();
        // [GIVEN] Create item with comment and item variant
        Comment := CreateItemWithCommentLine(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [WHEN] Run copy item report with Comments = "Yes", Item Variant = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Comments := true;
        CopyItemBuffer."Item Variants" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Comment line and item variant copied
        VerifyItemGeneralInformation(CopyItemBuffer."Target Item No.", Item.Description);
        VerifyCommentLine(CopyItemBuffer."Target Item No.", Comment);
        VerifyItemVariant(ItemVariant, CopyItemBuffer."Target Item No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithGeneralInformation()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with Unit of Measure
        Initialize();

        // [GIVEN] Create item with Unit of Measure
        LibraryInventory.CreateItem(Item);

        // [WHEN] Run copy item report with "Unit of Measure" = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."Units of Measure" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Unit of Measure copied
        VerifyItemGeneralInformation(CopyItemBuffer."Target Item No.", Item.Description);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndExtendedText()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        ExtendedTextLine: Record "Extended Text Line";
        Comment: Text[80];
    begin
        // [FEATURE] [Comments] [Extended Text]
        // [SCENARIO] Copy item with comment lines and Extended Text
        Initialize();

        // [GIVEN] Create item with comment and Extended Text
        Comment := CreateItemWithCommentLine(Item);
        CreateExtendedText(ExtendedTextLine, Item."No.");

        // [WHEN] Run copy item report with Comment = "Yes" and "Extended Text" = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Comments := true;
        CopyItemBuffer."Extended Texts" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Comment line and Extended Text copied
        VerifyCommentLine(CopyItemBuffer."Target Item No.", Comment);
        VerifyExtendedText(ExtendedTextLine, CopyItemBuffer."Target Item No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithItemCommentLineAndBOMComponent()
    var
        ParentItem: Record Item;
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        Comment: Text[80];
        QuantityPer: Decimal;
    begin
        // [FEATURE] [Comments]
        // [SCENARIO] Copy item with comment lines and BOM Component
        Initialize();

        // [GIVEN] Create item with comment and BOM Component
        QuantityPer := LibraryRandom.RandDec(10, 2);
        Comment := CreateItemWithCommentLine(ParentItem);
        LibraryInventory.CreateItem(Item);
        CreateBOMComponent(Item, ParentItem."No.", QuantityPer);

        // [WHEN] Run copy item report with Comment = "Yes" and "BOM Component" = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Comments := true;
        CopyItemBuffer."BOM Components" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(ParentItem."No.");

        // [THEN] Comment line and BOM Component copied
        VerifyCommentLine(CopyItemBuffer."Target Item No.", Comment);
        VerifyBOMComponent(CopyItemBuffer."Target Item No.", Item."No.", QuantityPer);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithTroubleShootingSetupAndResourceSkill()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        TroubleshootingSetup: Record "Troubleshooting Setup";
        TroubleshootingSetup2: Record "Troubleshooting Setup";
        ResourceSkill: Record "Resource Skill";
        ResourceSkill2: Record "Resource Skill";
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with Troubleshooting Setup and resource skill
        Initialize();

        // [GIVEN] Create item with Troubleshooting Setup
        LibraryInventory.CreateItem(Item);
        CreateTroubleShootingSetup(TroubleshootingSetup, Item."No.");
        CreateResourceSkill(ResourceSkill, Item."No.");

        // [WHEN] Run copy item report with "Troubleshooting Setup" = "Yes", "Resource Skills" = Yes
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."Resource Skills" := true;
        CopyItemBuffer.Troubleshooting := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Troubleshooting Setup and resource skill copied
        ResourceSkill2.Get(ResourceSkill.Type, CopyItemBuffer."Target Item No.", ResourceSkill."Skill Code");
        TroubleshootingSetup2.Get(TroubleshootingSetup.Type, CopyItemBuffer."Target Item No.", TroubleshootingSetup."Troubleshooting No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithPriceLists()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        PriceListHeader: array[2] of Record "Price List Header";
        PriceListLine: array[6] of Record "Price List Line";
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with Sales/Purchase Price Lists
        Initialize();
        PriceListHeader[1].DeleteAll();
        PriceListLine[1].DeleteAll();

        // [GIVEN] Create item with Sales/Purchase Prices and Line Discounts
        LibraryInventory.CreateItem(Item);
        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[1], "Price Type"::Sale, "Price Source Type"::"All Customers", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[1], PriceListHeader[1].Code, "Price Source Type"::"All Customers", '',
            "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine[2], PriceListHeader[1].Code, "Price Source Type"::"All Customers", '',
            "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[3], PriceListHeader[1].Code, "Price Source Type"::"All Customers", '',
            "Price Asset Type"::Item, Item."No.");
        PriceListLine[3]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[3]."Line Discount %" := 3;
        PriceListLine[3].Modify();

        LibraryPriceCalculation.CreatePriceHeader(
            PriceListHeader[2], "Price Type"::Purchase, "Price Source Type"::"All Vendors", '');
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[4], PriceListHeader[2].Code, "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreateSalesDiscountLine(
            PriceListLine[5], PriceListHeader[2].Code, "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, Item."No.");
        LibraryPriceCalculation.CreateSalesPriceLine(
            PriceListLine[6], PriceListHeader[2].Code, "Price Source Type"::"All Vendors", '',
            "Price Asset Type"::Item, Item."No.");
        PriceListLine[6]."Amount Type" := "Price Amount Type"::Any;
        PriceListLine[6]."Line Discount %" := 3;
        PriceListLine[6].Modify();

        // [WHEN] Run copy item report, where "Sales Price" = "Yes", "Sales Line Discount" = "Yes",
        // [WHEN] "Purchase Price" = "Yes", "Purchase Line Discount" = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."Sales Prices" := true;
        CopyItemBuffer."Sales Line Discounts" := true;
        CopyItemBuffer."Purchase Prices" := true;
        CopyItemBuffer."Purchase Line Discounts" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Sales/Purcchase Price and Line Discount copied
        VerifyPriceListLines(PriceListLine, CopyItemBuffer."Target Item No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithSalesPriceAndSalesLineDiscount()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        SalesPrice: Record "Sales Price";
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with Sales Price and Sales Line Discount
        Initialize();

        // [GIVEN] Create item with Sales Price and Sales Line Discount
        LibraryInventory.CreateItem(Item);
        CreateSalesPriceWithLineDiscount(SalesPrice, SalesLineDiscount, Item);

        // [WHEN] Run copy item report with "Sales Price" = "Yes" and "Sales Line Discount" = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."Sales Prices" := true;
        CopyItemBuffer."Sales Line Discounts" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Sales Price and Sales Line Discount copied
        VerifySalesPrice(SalesPrice, CopyItemBuffer."Target Item No.");
        VerifySalesLineDiscount(CopyItemBuffer."Target Item No.", SalesLineDiscount."Line Discount %");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithPurchasePriceAndPurchaseLineDiscount()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        // [FEATURE] [Copy Item]
        // [SCENARIO] Copy item with Purchase Price and Purchase Line Discount
        Initialize();

        // [GIVEN] Create item with Purchase Price and Purchase Line Discount
        LibraryInventory.CreateItem(Item);
        CreatePurchasePriceWithLineDiscount(PurchasePrice, PurchaseLineDiscount, Item);

        // [WHEN] Run copy item report with "Purchase Price" = "Yes" and "Purchase Line Discount" = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."Purchase Line Discounts" := true;
        CopyItemBuffer."Purchase Prices" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Purchase Price and Purchase Line Discount copied
        VerifyPurchasePrice(PurchasePrice, CopyItemBuffer."Target Item No.");
        VerifyPurchaseLineDiscount(PurchaseLineDiscount, CopyItemBuffer."Target Item No.");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyingItemWithSeveralCommentLines()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        CommentLine: Record "Comment Line";
        Comments: array[3] of Text;
        i: Integer;
    begin
        // [FEATURE] [Comments]
        // [SCENARIO 279990] Several comment lines are copied from the source item to a destination item.
        Initialize();

        // [GIVEN] Source item "S" with several comment lines, destination item "D".
        CreateItemWithSeveralCommentLines(Item, Comments);

        // [WHEN] Copy comment lines from item "S" to "D".
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Comments := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] All comment lines are successfully copied.
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        CommentLine.SetRange("No.", CopyItemBuffer."Target Item No.");
        for i := 1 to ArrayLen(Comments) do begin
            CommentLine.Next();
            CommentLine.TestField(Comment, Comments[i]);
        end;
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyingItemWithSeveralDefaultDimensions()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        SourceDefaultDimension: Record "Default Dimension";
        TargetDefaultDimension: Record "Default Dimension";
        NoOfDims: Integer;
        i: Integer;
    begin
        // [FEATURE] [Default Dimension]
        // [SCENARIO 280964] Several default dimensions are copied from the source item to a destination item.
        Initialize();

        // [GIVEN] Source item "S" with several default dimensions, destination item "D".
        LibraryInventory.CreateItem(Item);

        NoOfDims := LibraryRandom.RandIntInRange(2, 4);
        CreateSeveralDefaultDimensionsForItem(Item."No.", NoOfDims);

        // [WHEN] Copy default dimensions from item "S" to "D".
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Dimensions := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] All default dimensions and their values are successfully copied.
        SourceDefaultDimension.SetRange("Table ID", DATABASE::Item);
        SourceDefaultDimension.SetRange("No.", Item."No.");
        TargetDefaultDimension.CopyFilters(SourceDefaultDimension);
        for i := 1 to NoOfDims do begin
            SourceDefaultDimension.Next();
            TargetDefaultDimension.Next();
            TargetDefaultDimension.TestField("Dimension Code", SourceDefaultDimension."Dimension Code");
            TargetDefaultDimension.TestField("Dimension Value Code", SourceDefaultDimension."Dimension Value Code");
        end;
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler,ShowCreatedItemsSendNotificationHandler,ModalItemCardHandler')]
    [Scope('OnPrem')]
    procedure OpenTargetItemAfterCopyOnItemListPage()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 224152] Target Item Card opens after copying item
        Initialize();

        // [GIVEN] Source Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Target Item No.
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);

        // [WHEN] Copy Item
        CopyItemOnItemListPage(Item."No.");

        // [THEN] Item Card opens on target Item in modal mode
        Assert.AreEqual(CopyItemBuffer."Target Item No.", LibraryVariableStorage.DequeueText(), 'Invalid Item No.');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemAttributesPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithAttributesCopiesAttributesIntoNewItem()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
        NoOfAttributes: Integer;
        I: Integer;
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 264720] Item attributes are copied by the "Item Copy" job when the corresponding option is selected
        Initialize();

        // [GIVEN] Item "SRC" with 3 attributes
        LibraryInventory.CreateItem(Item);

        NoOfAttributes := LibraryRandom.RandIntInRange(3, 5);
        for I := 1 to NoOfAttributes do
            CreateItemAttributeMappedToItem(Item."No.");

        // [WHEN] Copy item "SRC" into a new item "DST" with "Copy Attributes" option selected
        TargetItemNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(TargetItemNo);
        LibraryVariableStorage.Enqueue(true);
        CopyItem(Item."No.");

        // [THEN] All attributes are copied from "SRC" to "DST"
        VerifyItemAttributes(Item."No.", TargetItemNo);

        LibraryVariableStorage.AssertEmpty();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemAttributesPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithAttributesDoesNotCopyAttributesWithAttrOptionDisabled()
    var
        Item: Record Item;
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        TargetItemNo: Code[20];
    begin
        // [FEATURE] [Item Attribute]
        // [SCENARIO 264720] Item attributes are not copied by the "Item Copy" job when the corresponding option is disabled
        Initialize();

        // [GIVEN] Item "SRC" with attribute
        LibraryInventory.CreateItem(Item);
        CreateItemAttributeMappedToItem(Item."No.");

        // [WHEN] Copy item "SRC" into a new item "DST" with "Copy Attributes" option switched off
        TargetItemNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(TargetItemNo);
        LibraryVariableStorage.Enqueue(false);
        CopyItem(Item."No.");

        // [THEN] Item "SRC" is copied to "DST" without attributes
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        ItemAttributeValueMapping.SetRange("No.", TargetItemNo);
        Assert.RecordIsEmpty(ItemAttributeValueMapping);

        LibraryVariableStorage.AssertEmpty();
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure ItemUnitsOfMeasureNotCopiedWhenRunCopyItemWithUoMOptionDisabled()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 273790] Report "Copy Item" resets values of item's alternative units of measure if the option "Units of measure" is not selected
        Initialize();

        // [GIVEN] Item with alternative units of measure in the card: "Sales Unit of Measure", "Purch. Unit of Measure" and "Put-away Unit of Measure"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [WHEN] Run "Item Copy" report for item "I" for item "I" with option "Item General Information" selected. All other options are disabled.
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."General Item Information" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Item units of measure are not copied. "Base Unit of Measure", "Purch. Unit of Measure", "Sales Unit of Measure", "Put-away Unit of Measure" in the new item are blank
        ItemUnitOfMeasure.SetRange("Item No.", CopyItemBuffer."Target Item No.");
        Assert.RecordIsEmpty(ItemUnitOfMeasure);

        Item.Get(CopyItemBuffer."Target Item No.");
        Item.TestField("Base Unit of Measure", '');
        Item.TestField("Purch. Unit of Measure", '');
        Item.TestField("Sales Unit of Measure", '');
        Item.TestField("Put-away Unit of Measure Code", '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure ItemUnitsOfMeasureCopiedWhenRunCopyItemWithUoMOptionEnabled()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        ItemUnitOfMeasure: array[4] of Record "Item Unit of Measure";
        I: Integer;
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 273790] Report "Copy Item" copies item's alternative units of measure if the option "Units of measure" is selected
        Initialize();

        // [GIVEN] Item with alternative units of measure in the card.
        // [GIVEN] "Purch. Unit of Measure" = "U1", "Sales Unit of Measure" = "U2", "Put-away Unit of Measure" = "U3"
        LibraryInventory.CreateItem(Item);

        for I := 1 to 3 do
            LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure[I], Item."No.", LibraryRandom.RandInt(10));

        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure[1].Code);
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure[2].Code);
        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure[3].Code);
        Item.Modify(true);

        // [WHEN] Run "Item Copy" report for item "I" for item "I" with option "Units of measure" selected
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."Units of Measure" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Alternative units of measure are copied to the new item. "Purch. Unit of Measure" = "U1", "Sales Unit of Measure" = "U2", "Put-away Unit of Measure" = "U3"
        Item.Get(CopyItemBuffer."Target Item No.");
        Item.TestField("Purch. Unit of Measure", ItemUnitOfMeasure[1].Code);
        Item.TestField("Sales Unit of Measure", ItemUnitOfMeasure[2].Code);
        Item.TestField("Put-away Unit of Measure Code", ItemUnitOfMeasure[3].Code);

        for I := 1 to 3 do
            VerifyItemUnitOfMeasure(CopyItemBuffer."Target Item No.", ItemUnitOfMeasure[I].Code);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemGetTargetItemNosPageHandler')]
    [Scope('OnPrem')]
    procedure DefaultTargetItemNosValue()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
    begin
        // [SCENARIO 296337] Report Copy Item has default "Target Item Nos." = InventorySetup."Item Nos."
        Initialize();

        // [GIVEN] Inventory Setup with "Item Nos." = "INOS"
        LibraryInventory.CreateItem(Item);

        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", LibraryERM.CreateNoSeriesCode());
        InventorySetup.Modify();

        // [WHEN] Report "Copy Item" is being run
        Commit();
        CopyItem(Item."No.");

        // [THEN] "Target Item Nos." = "INOS"
        Assert.AreEqual(InventorySetup."Item Nos.", LibraryVariableStorage.DequeueText(), 'Invalid Target Item Nos.');
    end;

    [Test]
    [HandlerFunctions('CopyItemNumberOfEntriesTargetNoPageHandler')]
    [Scope('OnPrem')]
    procedure TargetItemNoCheckWhenNuberOfCopiesGreaterThanOne()
    var
        Item: Record Item;
        NumberOfCopies: Integer;
    begin
        // [SCENARIO 296337] Target Item No must be incrementable when Number of Copies > 1
        Initialize();

        // [GIVEN]
        LibraryInventory.CreateItem(Item);

        // [WHEN] Run "Item Copy" report for item "I" for item "I" with Number Of Copies = 5 and Targed Item No. = "ABC"
        NumberOfCopies := LibraryRandom.RandIntInRange(5, 10);
        LibraryVariableStorage.Enqueue('ABC');
        LibraryVariableStorage.Enqueue(NumberOfCopies);
        asserterror CopyItem(Item."No.");

        // [THEN] Error "Target Item No. contains no number and cannot be incremented."
        Assert.ExpectedError(STRSUBSTNO(UnincrementableStringErr, TargetItemNoTxt));
    end;

    [Test]
    [HandlerFunctions('CopyItemSetTargetItemNosPageHandler,NoSeriesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemUsingTargetNumberSeries()
    var
        Item: Record Item;
        NoSeries: Codeunit "No. Series";
        TargetItemNo: Code[20];
        NoSeriesCode: Code[10];
    begin
        // [SCENARIO 296337] Report Copy Item creates new item using "Target No. Series" parameter
        Initialize();

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Number series "NOS" with next number "ITEM1"
        NoSeriesCode := CreateUniqItemNoSeries();
        TargetItemNo := NoSeries.PeekNextNo(NoSeriesCode);

        // [WHEN] Run "Item Copy" report for item "I" with parameter "Target No. Series" = "NOS"
        LibraryVariableStorage.Enqueue(NoSeriesCode);
        CopyItem(Item."No.");

        // [THEN] New item created with "No." = "ITEM1"
        VerifyItemGeneralInformation(TargetItemNo, Item.Description);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemNumberOfEntriesPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithNumberOfCopiesMoreThanOneUseNumberSeries()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        NoSeries: Codeunit "No. Series";
        TargetItemNo: Code[20];
        NumberOfCopies: Integer;
        i: Integer;
    begin
        // [SCENARIO 296337] User is able to create serveral item copies with parameter Number Of Copies and number series
        Initialize();

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);
        // Remember next number from InventorySetup."Item Nos."
        InventorySetup.Get();
        TargetItemNo := NoSeries.PeekNextNo(InventorySetup."Item Nos.");

        // [WHEN] Run "Item Copy" report for item "I" for item "I" with Number Of Copies = 5
        NumberOfCopies := LibraryRandom.RandIntInRange(5, 10);
        LibraryVariableStorage.Enqueue(NumberOfCopies);
        CopyItem(Item."No.");

        // [THEN] 5 new items created
        for i := 1 to NumberOfCopies do begin
            if i > 1 then
                TargetItemNo := IncStr(TargetItemNo);
            VerifyItemGeneralInformation(TargetItemNo, Item.Description);
        end;
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemNumberOfEntriesTargetNoPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithNumberOfCopiesMoreThanOneUseTargetItemNo()
    var
        Item: Record Item;
        TargetItemNo: Code[20];
        NumberOfCopies: Integer;
        i: Integer;
    begin
        // [SCENARIO 296337] User is able to create serveral item copies with parameter Number Of Copies and manual Target Item No.
        Initialize();

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [WHEN] Run "Item Copy" report for item "I" with Number Of Copies = 5
        NumberOfCopies := LibraryRandom.RandIntInRange(5, 10);
        TargetItemNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(TargetItemNo);
        LibraryVariableStorage.Enqueue(NumberOfCopies);
        CopyItem(Item."No.");

        // [THEN] 5 new items created
        for i := 1 to NumberOfCopies do begin
            if i > 1 then
                TargetItemNo := IncStr(TargetItemNo);
            VerifyItemGeneralInformation(TargetItemNo, Item.Description);
        end;
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemNumberOfEntriesPageHandler,ShowCreatedItemsSendNotificationHandler,ModalItemListHandler')]
    [Scope('OnPrem')]
    procedure OpenCopiedItemsListWhenNumberOfCopiesMoreThanOne()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        NoSeries: Codeunit "No. Series";
        FirstItemNo: Code[20];
        LastItemNo: Code[20];
        NumberOfCopies: Integer;
        i: Integer;
    begin
        // [SCENARIO 296337] Report "Copy Item" opens item list with filtered created items
        Initialize();

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);
        // Remember next number from InventorySetup."Item Nos."
        InventorySetup.Get();
        FirstItemNo := NoSeries.PeekNextNo(InventorySetup."Item Nos.");
        LastItemNo := FirstItemNo;

        // [GIVEN] Run "Item Copy" report for item "I" with Number Of Copies = 5
        NumberOfCopies := LibraryRandom.RandIntInRange(5, 10);
        LibraryVariableStorage.Enqueue(NumberOfCopies);
        CopyItem(Item."No.");

        // [WHEN] Select "Show created items" notification action (in the ShowCreatedItemsSendNotificationHandler)
        // [THEN] Item list page opened with filter "ITEM1..ITEM5"
        for i := 1 to NumberOfCopies do
            if i > 1 then
                LastItemNo := IncStr(LastItemNo);
        Assert.AreEqual(
          StrSubstNo('%1..%2', FirstItemNo, LastItemNo),
          LibraryVariableStorage.DequeueText(),
          'Invalid item No. filter');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemNumberOfEntriesTargetNoPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithTargetItemNoAndItemNosManualNo()
    var
        Item: Record Item;
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
        TargetItemNo: Code[20];
    begin
        // [SCENARIO 296337] User should not be able to use target item number if InventorySetup."Item Nos." has Manual Nos. = No
        Initialize();

        // [GIVEN] Item "I"
        LibraryInventory.CreateItem(Item);

        // [GIVEN] InventorySetup with "Item Nos." = "ITEMNOS" with "Manual Nos." = No
        LibraryUtility.CreateNoSeries(NoSeries, true, false, false);
        InventorySetup.Get();
        InventorySetup.Validate("Item Nos.", NoSeries.Code);
        InventorySetup.Modify(true);

        // [WHEN] Run "Copy Item" with default "Target Item No." = "ITEM1"
        TargetItemNo := LibraryUtility.GenerateGUID();
        LibraryVariableStorage.Enqueue(TargetItemNo);
        LibraryVariableStorage.Enqueue(1);
        asserterror CopyItem(Item."No.");

        // [THEN] Error "You may not enter numbers manually..."
        Assert.ExpectedError('You may not enter numbers manually');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringSalesLinesUseItemDescriptionTranslation()
    var
        SalesHeader: Record "Sales Header";
        StandardSalesLine: Record "Standard Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        Customer: Record Customer;
        SalesLine: Record "Sales Line";
        Description: Text;
    begin
        // [FEATURE] [Recurring Sales Lines] [Item translation]
        // [SCENARIO 319744] ApplyStdCodesToSalesLines function in table 'Standard Customer Sales Code' uses Item Translation
        Initialize();

        // [GIVEN] Item "I1" with Description = "D1"
        // [GIVEN] Customer "C1" with Standard Sales Line defned for "I1" and 'Landuage Code' = "X"
        CreateStandardSalesLinesWithItemForCustomer(StandardSalesLine, StandardCustomerSalesCode);
        Customer.Get(StandardCustomerSalesCode."Customer No.");
        Customer.Validate("Language Code", LibraryERM.GetAnyLanguageDifferentFromCurrent());
        Customer.Modify(true);
        // [GIVEN] "I1" has a translation for Landuage Code "X" = "D2"
        Description := CreateItemTranslationWithRecord(StandardSalesLine."No.", Customer."Language Code");

        // [WHEN] Run ApplyStdCodesToSalesLines with Sales Order for "C1"
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        StandardCustomerSalesCode.ApplyStdCodesToSalesLines(SalesHeader, StandardCustomerSalesCode);

        // [THEN] Sales Line created, Description = "D2"
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField(Description, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringPurchaseLinesUseItemDescriptionTranslation()
    var
        PurchaseHeader: Record "Purchase Header";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        Description: Text;
    begin
        // [FEATURE] [Recurring Purchase Lines] [Item translation]
        // [SCENARIO 319744] ApplyStdCodesToPurchaseLines function in table 'Standard Vendor Purchase Code' uses Item Translation
        Initialize();

        // [GIVEN] Item "I1" with Description = "D1"
        // [GIVEN] Vendor "V1" with Standard Purchase Line defned for "I1" and 'Landuage Code' = "X"
        CreateStandardPurchaseLinesWithItemForVendor(StandardPurchaseLine, StandardVendorPurchaseCode);
        Vendor.Get(StandardVendorPurchaseCode."Vendor No.");
        Vendor.Validate("Language Code", LibraryERM.GetAnyLanguageDifferentFromCurrent());
        Vendor.Modify(true);

        // [GIVEN] "I1" has a translation for Landuage Code "X" = "D2"
        Description := CreateItemTranslationWithRecord(StandardPurchaseLine."No.", Vendor."Language Code");

        // [WHEN] Run ApplyStdCodesToPurchaseLines with Purchase Order for "V1"
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        StandardVendorPurchaseCode.ApplyStdCodesToPurchaseLines(PurchaseHeader, StandardVendorPurchaseCode);

        // [THEN] Purchase Line created, Description = "D2"
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Description, Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringSalesLinesUseSetStandardItemDescription()
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        StandardSalesLine: Record "Standard Sales Line";
    begin
        // [FEATURE] [Recurring Sales Lines]
        // [SCENARIO 337249] ApplyStdCodesToSalesLines function in table 'Standard Customer Sales Code' uses Set Standard Item Description
        Initialize();

        // [GIVEN] Item "I1" with Description = "D1"
        // [GIVEN] Customer "C1" with Standard Sales Line defned for "I1" and 'Description' = "D2"
        CreateStandardSalesLinesWithItemForCustomer(StandardSalesLine, StandardCustomerSalesCode);
        StandardSalesLine.Validate(Description, LibraryUtility.GenerateRandomXMLText(MaxStrLen(StandardSalesLine.Description)));
        StandardSalesLine.Modify(true);

        // [WHEN] Run ApplyStdCodesToSalesLines with Sales Order for "C1"
        Customer.Get(StandardCustomerSalesCode."Customer No.");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        StandardCustomerSalesCode.ApplyStdCodesToSalesLines(SalesHeader, StandardCustomerSalesCode);

        // [THEN] Created Sales Line has Description = "D2"
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        SalesLine.TestField(Description, StandardSalesLine.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringPurchaseLinesUseSetStandardItemDescription()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Recurring Purchase Lines]
        // [SCENARIO 337249] ApplyStdCodesToPurchaseLines function in table 'Standard Vendor Purchase Code' uses SetStandard Item Description
        Initialize();

        // [GIVEN] Item "I1" with Description = "D1"
        // [GIVEN] Vendor "V1" with Standard Purchase Line defned for "I1" and 'Description' = "D2"
        CreateStandardPurchaseLinesWithItemForVendor(StandardPurchaseLine, StandardVendorPurchaseCode);
        StandardPurchaseLine.Validate(Description, LibraryUtility.GenerateRandomXMLText(MaxStrLen(StandardPurchaseLine.Description)));
        StandardPurchaseLine.Modify(true);

        // [WHEN] Run ApplyStdCodesToPurchaseLines with Purchase Order for "V1"
        Vendor.Get(StandardVendorPurchaseCode."Vendor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        StandardVendorPurchaseCode.ApplyStdCodesToPurchaseLines(PurchaseHeader, StandardVendorPurchaseCode);

        // [THEN] Created Purchase Line has Description = "D2"
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Description, StandardPurchaseLine.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringSalesLinesUseDefaultItemDescription()
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        StandardSalesLine: Record "Standard Sales Line";
    begin
        // [FEATURE] [Recurring Sales Lines]
        // [SCENARIO 337249] ApplyStdCodesToSalesLines function in table 'Standard Customer Sales Code' uses Default Item Description when Standard Description = ''
        Initialize();

        // [GIVEN] Item "I1" with Description = "D1"
        // [GIVEN] Customer "C1" with Standard Sales Line defned for "I1" and 'Description' = ''
        CreateStandardSalesLinesWithItemForCustomer(StandardSalesLine, StandardCustomerSalesCode);

        // [WHEN] Run ApplyStdCodesToSalesLines with Sales Order for "C1"
        Customer.Get(StandardCustomerSalesCode."Customer No.");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        StandardCustomerSalesCode.ApplyStdCodesToSalesLines(SalesHeader, StandardCustomerSalesCode);

        // [THEN] Created Sales Line has Description = "D1"
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.FindFirst();
        Item.Get(SalesLine."No.");
        SalesLine.TestField(Description, Item.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RecurringPurchaseLinesUseDefaultItemDescription()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        Vendor: Record Vendor;
    begin
        // [FEATURE] [Recurring Purchase Lines]
        // [SCENARIO 337249] ApplyStdCodesToPurchaseLines function in table 'Standard Vendor Purchase Code' uses Default Item Description when Standard Description = ''
        Initialize();

        // [GIVEN] Item "I1" with Description = "D1"
        // [GIVEN] Vendor "V1" with Standard Purchase Line defned for "I1" and 'Description' = ''
        CreateStandardPurchaseLinesWithItemForVendor(StandardPurchaseLine, StandardVendorPurchaseCode);

        // [WHEN] Run ApplyStdCodesToPurchaseLines with Purchase Order for "V1"
        Vendor.Get(StandardVendorPurchaseCode."Vendor No.");
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        StandardVendorPurchaseCode.ApplyStdCodesToPurchaseLines(PurchaseHeader, StandardVendorPurchaseCode);

        // [THEN] Created Purchase Line has Description = "D1"
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();
        Item.Get(PurchaseLine."No.");
        PurchaseLine.TestField(Description, Item.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UseCopyItemCodeunit()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        CopyItemCodeunit: Codeunit "Copy Item";
        Comment: Text[80];
    begin
        // [FEATURE] [UT]
        // [SCENARIO 346157] Copy item functionality could be used directly without parameters page
        Initialize();

        // [GIVEN] Item "I" with Comment Line
        Comment := CreateItemWithCommentLine(Item);

        // [GIVEN] Prepare CopyItemBuffer
        CopyItemBuffer."Source Item No." := Item."No.";
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer.Comments := true;
        CopyItemBuffer."Units of Measure" := true;
        CopyItemBuffer."Number of Copies" := 1;

        // [WHEN] Run DoCopyItem function
        CopyItemCodeunit.SetCopyItemBuffer(CopyItemBuffer);
        CopyItemCodeunit.DoCopyItem();

        // [THEN] Comment line copied
        VerifyItemGeneralInformation(CopyItemBuffer."Target Item No.", Item.Description);
        VerifyCommentLine(CopyItemBuffer."Target Item No.", Comment);
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure LastUsedValuesSaved()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        CopyItemParameters: Record "Copy Item Parameters";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 360665] Copy item functionality keeps last used parameters values 
        Initialize();

        // [GIVEN] Item "I" 
        LibraryInventory.CreateItem(Item);

        // [WHEN] Run copy item report with Comment = "Yes" and "Units of Measure" = "Yes"
        CopyItemBuffer.Comments := true;
        CopyItemBuffer."Units of Measure" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Copy Item Parameters entry created for current user with Comment = "Yes" and "Units of Measure" = "Yes"
        CopyItemParameters.Get(UserId());
        CopyItemParameters.TestField(Comments, true);
        CopyItemParameters.TestField("Units of Measure", true);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemCheckCommentsAndUnitOfMeasurePageHandler')]
    [Scope('OnPrem')]
    procedure ValuesFromCopyItemParameters()
    var
        Item: Record Item;
        CopyItemParameters: Record "Copy Item Parameters";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 360665] Page Copy Item uses parameters from Copy Item Parameters 
        Initialize();

        // [GIVEN] Item "I" 
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Mock Copy Item Parameters for current user with Comment = "Yes" and "Units of Measure" = "Yes"
        CopyItemParameters.DeleteAll();
        CopyItemParameters."User ID" := UserId();
        CopyItemParameters.Comments := true;
        CopyItemParameters."Units of Measure" := true;
        CopyItemParameters.Insert();

        // [WHEN] Run copy item function 
        CopyItem(Item."No.");

        // [THEN] Copy Item page has Comment = "Yes" and "Units of Measure" = "Yes"
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Comment must be Yes');
        Assert.IsTrue(LibraryVariableStorage.DequeueBoolean(), 'Units of Measure must be Yes');
    end;

    [Test]
    [HandlerFunctions('CopyItemCheckSourceItemNoPageHandler')]
    [Scope('OnPrem')]
    procedure SourceItemNo()
    var
        Item: array[2] of Record Item;
        CopyItemParameters: Record "Copy Item Parameters";
    begin
        // [FEATURE] [UI]
        // [SCENARIO 364110] Source item number initialized correctly after previous item was copied
        Initialize();

        // [GIVEN] Item "I1" 
        LibraryInventory.CreateItem(Item[1]);
        // [GIVEN] Item "I2" 
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Mock Copy Item Parameters for current user with "Source Item No." = "I1"
        CopyItemParameters.DeleteAll();
        CopyItemParameters."User ID" := UserId();
        CopyItemParameters."Source Item No." := Item[1]."No.";
        CopyItemParameters.Insert();

        // [WHEN] Run copy item function 
        CopyItem(Item[2]."No.");

        // [THEN] Copy Item page has "Source Item No." = "I2"
        Assert.AreEqual(Item[2]."No.", LibraryVariableStorage.DequeueText(), 'Invalid Source Item No.');
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemVariantWithTargetItemId()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        ItemVariant: Record "Item Variant";
    begin
        // [FEATURE] [Item Variant]
        // [SCENARIO 371182] Item Variant copy has "Item Id" of the Item's created copy
        Initialize();

        // [GIVEN] Create item with item variant
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [WHEN] Run copy item report with Item Variant = "Yes"
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."Item Variants" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Item Variant copied with "Item Id" of the target item
        Item.Get(CopyItemBuffer."Target Item No.");
        ItemVariant.Get(CopyItemBuffer."Target Item No.", ItemVariant.Code);
        ItemVariant.TestField("Item Id", Item.SystemId);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemWithoutGeneralInformationPageHandler')]
    [Scope('OnPrem')]
    procedure ItemUnitsOfMeasuresFieldNotCopiedWhenRunItemCopyWithUoMandGIOptionsDisabled()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [Item Unit of Measure]
        // [SCENARIO 379540] Report "Copy Item" resets values of item's alternative units of measure if the options "Units of measure" and "General Information" are not selected
        Initialize();

        // [GIVEN] Item with alternative units of measure in the card: "Sales Unit of Measure", "Purch. Unit of Measure" and "Put-away Unit of Measure"
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(10));
        Item.Validate("Sales Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Put-away Unit of Measure Code", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [WHEN] Run "Item Copy" report for item "I" for item "I" when all options are disabled.
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."General Item Information" := false;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Item units of measure are not copied. "Base Unit of Measure", "Purch. Unit of Measure", "Sales Unit of Measure", "Put-away Unit of Measure" in the new item are blank
        ItemUnitOfMeasure.SetRange("Item No.", CopyItemBuffer."Target Item No.");
        Assert.RecordIsEmpty(ItemUnitOfMeasure);

        Item.Get(CopyItemBuffer."Target Item No.");
        Item.TestField("Base Unit of Measure", '');
        Item.TestField("Purch. Unit of Measure", '');
        Item.TestField("Sales Unit of Measure", '');
        Item.TestField("Put-away Unit of Measure Code", '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemWithoutGeneralInformationPageHandler')]
    [Scope('OnPrem')]
    procedure ItemGlobalDimensionssFieldNotCopiedWhenRunItemCopyWithDandGIOptionsDisabled()
    var
        Item: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
        DimensionValue: array[2] of Record "Dimension Value";
    begin
        // [FEATURE] [Global Dimension]
        // [SCENARIO 379540] Report "Copy Item" resets values of item's global dimensions if the options "Dimensions" and "General Information" are not selected
        Initialize();

        // [GIVEN] Item with Global Dimensions codes
        LibraryInventory.CreateItem(Item);
        LibraryDimension.GetGlobalDimCodeValue(1, DimensionValue[1]);
        LibraryDimension.GetGlobalDimCodeValue(2, DimensionValue[2]);
        Item.Validate("Global Dimension 1 Code", DimensionValue[1].Code);
        Item.Validate("Global Dimension 2 Code", DimensionValue[2].Code);
        Item.Modify(true);

        // [WHEN] Run "Item Copy" report for item "I" for item "I" when all options are disabled.
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."General Item Information" := false;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [THEN] Item global dimensions are not copied. "Global Dimension 1 Code", "Global Dimension 2 Code" in the new item are blank
        Item.Get(CopyItemBuffer."Target Item No.");
        Item.TestField("Global Dimension 1 Code", '');
        Item.TestField("Global Dimension 2 Code", '');
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemSetTargetItemNosPageHandler,NoSeriesListModalPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemWithTargetNoSeriesDiffFromInvtSetup()
    var
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        NoSeries: Record "No. Series";
        SavedNoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NoSeriesCodeunit: Codeunit "No. Series";
        TargetItemNo: Code[20];
        NoSeriesCode: Code[20];
    begin
        // [FEATURE] [No. Series]
        // [SCENARIO 413076] Copying item when target no. series has "Default Nos." = TRUE and default item no. series in Inventory Setup has "Default Nos." = FALSE.
        Initialize();

        // [GIVEN] Item "I".
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Set "Default Nos." = FALSE for default item no. series in Inventory Setup.
        InventorySetup.Get();
        NoSeries.Get(InventorySetup."Item Nos.");
        NoSeries.Validate("Default Nos.", false);
        NoSeries.Modify(true);
        SavedNoSeries := NoSeries;

        // [GIVEN] New no. series "ITEM-X" with next number "X-00001" and "Default Nos." = TRUE.
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, LibraryUtility.GenerateGUID(), LibraryUtility.GenerateGUID());
        LibraryNoSeries.CreateNoSeriesRelationship(InventorySetup."Item Nos.", NoSeries.Code);
        NoSeriesCode := NoSeries.Code;
        TargetItemNo := NoSeriesCodeunit.PeekNextNo(NoSeriesCode);

        // [WHEN] Run "Item Copy" report for item "I" with parameter "Target No. Series" = "ITEM-X".
        LibraryVariableStorage.Enqueue(NoSeriesCode);
        CopyItem(Item."No.");

        // [THEN] New item created with "No." = "X-00001".
        VerifyItemGeneralInformation(TargetItemNo, Item.Description);

        // Teardown
        SavedNoSeries.Validate("Default Nos.", true);
        SavedNoSeries.Modify(true);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('CopyItemItemReferencesPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemPageSavesItemReferencesParameter()
    var
        Item: Record Item;
        CopyItemParameters: Record "Copy Item Parameters";
    begin
        // [FEATURE] [Item References]
        // [SCENARIO 420320] Parameter "Item References" saved when copying item
        Initialize();
        // [GIVEN] Item "I".
        LibraryInventory.CreateItem(Item);

        // [WHEN] Run "Item Copy" report for item "I" with parameter "Item References" = yes (CopyItemItemReferencesPageHandler)
        CopyItem(Item."No.");

        // [THEN] Copy Item Parameters entry created for current user with "Item References" = "Yes"
        CopyItemParameters.Get(UserId());
        CopyItemParameters.TestField("Item References", true);

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifySalesOrderCreationForCustomerWhenRecurringSalesLinesIsAutoInsert()
    var
        StandardSalesLine: Record "Standard Sales Line";
        StandardCustomerSalesCode: Record "Standard Customer Sales Code";
        Customer: Record Customer;
        SalesOrder: TestPage "Sales Order";
    begin
        // [SCENARIO 452461] The Sales Header does not exist. Identification fields and values: Document Type='Order',No.='X' when creating a Sales Order for a Customer with Recurring Lines setup to be inserted automatically.
        Initialize();

        // [GIVEN] Creation of Recurring Sales Lines & Customer with Std. Sales Code where Insert Rec. Lines On Orders = Automatic
        CreateStandardSalesLinesWithItemForCustomer(StandardSalesLine, StandardCustomerSalesCode);
        Customer.Get(StandardCustomerSalesCode."Customer No.");

        // [WHEN] Open new sales order & Set customer name.
        SalesOrder.OpenNew();
        SalesOrder."Sell-to Customer Name".SetValue(Customer.Name);

        // [THEN] Verify the sell-to customer name assigned without any error.
        Assert.AreEqual(SalesOrder."Sell-to Customer Name".Value, Customer.Name, CustomerNameErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPurchaseOrderCreationWhenRecurringPurchaseLinesIsAutoInsert()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        VendorCard: TestPage "Vendor Card";
        PurchaseOrder: TestPage "Purchase Order";
    begin
        // [SCENARIO 492853] The error message Purchase Header does not exist appears not allowing user to create a Purchase document from Vendor Card if the Vendor has an Automatic Recurring Purchase line.
        Initialize();

        // [GIVEN] Enable the new sales price feature.
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Creation of Recurring Purchase Lines & Vendor with Std. Purchaser Code where Insert Rec. Lines On Orders = Automatic.
        CreateStandardPurchaseLinesWithGLForVendor(StandardPurchaseLine, StandardVendorPurchaseCode, "Purchase Line Type"::"G/L Account");
        StandardVendorPurchaseCode.Validate("Insert Rec. Lines On Orders", StandardVendorPurchaseCode."Insert Rec. Lines On Orders"::Automatic);
        StandardVendorPurchaseCode.Modify(true);

        // [GIVEN] Open the vendor card.
        Vendor.Get(StandardVendorPurchaseCode."Vendor No.");
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [GIVEN] Create a new purchase order.
        PurchaseOrder.Trap();
        VendorCard.NewPurchaseOrder.Invoke();

        // [WHEN] Validate a field.
        PurchaseOrder."Vendor Order No.".SetValue('');

        // [VERIFY] Verify the purchase line is successfully inserted.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrder."No.".Value());
        Assert.RecordIsNotEmpty(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPurchaseInvoiceCreationWhenRecurringPurchaseLinesIsAutoInsert()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        VendorCard: TestPage "Vendor Card";
        PurchaseInvoice: TestPage "Purchase Invoice";
    begin
        // [SCENARIO 492853] The error message Purchase Header does not exist appears not allowing user to create a Purchase document from Vendor Card if the Vendor has an Automatic Recurring Purchase line.
        Initialize();

        // [GIVEN] Enable the new sales price feature.
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Creation of Recurring Purchase Lines & Vendor with Std. Purchaser Code where Insert Rec. Lines On Orders = Automatic.
        CreateStandardPurchaseLinesWithGLForVendor(StandardPurchaseLine, StandardVendorPurchaseCode, "Purchase Line Type"::"G/L Account");
        StandardVendorPurchaseCode.Validate("Insert Rec. Lines On Invoices", StandardVendorPurchaseCode."Insert Rec. Lines On Invoices"::Automatic);
        StandardVendorPurchaseCode.Modify(true);

        // [GIVEN] Open the vendor card.
        Vendor.Get(StandardVendorPurchaseCode."Vendor No.");
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [GIVEN] Create a new purchase invoice.
        PurchaseInvoice.Trap();
        VendorCard.NewPurchaseInvoice.Invoke();

        // [WHEN] Validate a field.
        PurchaseInvoice."Vendor Invoice No.".SetValue('');

        // [VERIFY] Verify the purchase line is successfully inserted.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Invoice);
        PurchaseLine.SetRange("Document No.", PurchaseInvoice."No.".Value());
        Assert.RecordIsNotEmpty(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPurchaseCrMemoCreationWhenRecurringPurchaseLinesIsAutoInsert()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        VendorCard: TestPage "Vendor Card";
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        // [SCENARIO 492853] The error message Purchase Header does not exist appears not allowing user to create a Purchase document from Vendor Card if the Vendor has an Automatic Recurring Purchase line.
        Initialize();

        // [GIVEN] Enable the new sales price feature.
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Creation of Recurring Purchase Lines & Vendor with Std. Purchaser Code where Insert Rec. Lines On Orders = Automatic.
        CreateStandardPurchaseLinesWithGLForVendor(StandardPurchaseLine, StandardVendorPurchaseCode, "Purchase Line Type"::"G/L Account");
        StandardVendorPurchaseCode.Validate("Insert Rec. Lines On Cr. Memos", StandardVendorPurchaseCode."Insert Rec. Lines On Invoices"::Automatic);
        StandardVendorPurchaseCode.Modify(true);

        // [GIVEN] Open the vendor card.
        Vendor.Get(StandardVendorPurchaseCode."Vendor No.");
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [GIVEN] Create a new purchase cr memo.
        PurchaseCreditMemo.Trap();
        VendorCard.NewPurchaseCrMemo.Invoke();

        // [WHEN] Validate a field.
        PurchaseCreditMemo."Vendor Cr. Memo No.".SetValue('');

        // [VERIFY] Verify the purchase line is successfully inserted.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::"Credit Memo");
        PurchaseLine.SetRange("Document No.", PurchaseCreditMemo."No.".Value());
        Assert.RecordIsNotEmpty(PurchaseLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPurchaseQuoteCreationWhenRecurringPurchaseLinesIsAutoInsert()
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        StandardPurchaseLine: Record "Standard Purchase Line";
        StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        VendorCard: TestPage "Vendor Card";
        PurchaseQuote: TestPage "Purchase Quote";
    begin
        // [SCENARIO 492853] The error message Purchase Header does not exist appears not allowing user to create a Purchase document from Vendor Card if the Vendor has an Automatic Recurring Purchase line.
        Initialize();

        // [GIVEN] Enable the new sales price feature.
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Creation of Recurring Purchase Lines & Vendor with Std. Purchaser Code where Insert Rec. Lines On Orders = Automatic.
        CreateStandardPurchaseLinesWithGLForVendor(StandardPurchaseLine, StandardVendorPurchaseCode, "Purchase Line Type"::"G/L Account");
        StandardVendorPurchaseCode.Validate("Insert Rec. Lines On Quotes", StandardVendorPurchaseCode."Insert Rec. Lines On Invoices"::Automatic);
        StandardVendorPurchaseCode.Modify(true);

        // [GIVEN] Open the vendor card.
        Vendor.Get(StandardVendorPurchaseCode."Vendor No.");
        VendorCard.OpenEdit();
        VendorCard.GotoRecord(Vendor);

        // [GIVEN] Create a new purchase quote.
        PurchaseQuote.Trap();
        VendorCard.NewPurchaseQuote.Invoke();

        // [WHEN] Validate a field.
        PurchaseQuote."Vendor Order No.".SetValue('');

        // [VERIFY] Verify the purchase line is successfully inserted.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Quote);
        PurchaseLine.SetRange("Document No.", PurchaseQuote."No.".Value());
        Assert.RecordIsNotEmpty(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    [Scope('OnPrem')]
    procedure CopyItemCostIsAdjustedSetToTrue()
    var
        SourceItem: Record Item;
        TargetItem: Record Item;
        CopyItemBuffer: Record "Copy Item Buffer";
    begin
        // [FEATURE] Copy Item [Cost is Adjusted = True]
        // [SCENARIO] When copying an item, the new item should have 'Cost is Adjusted' = TRUE regardless of source item value
        Initialize();

        // [GIVEN] Create item with 'Cost is Adjusted' = FALSE (simulating an item with unadjusted cost)
        LibraryInventory.CreateItem(SourceItem);
        SourceItem."Cost is Adjusted" := false;
        SourceItem.Modify();

        // [WHEN] Copy the item
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        CopyItemBuffer."Units of Measure" := true;
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(SourceItem."No.");

        // [THEN] The new item has 'Cost is Adjusted' = TRUE
        TargetItem.Get(CopyItemBuffer."Target Item No.");
        Assert.IsTrue(TargetItem."Cost is Adjusted", CostAdjustedTrueErr);
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"ERM Copy Item");
        ClearCopyItemParameters();

        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"ERM Copy Item");

        IsInitialized := true;
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();

        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"ERM Copy Item");
    end;

    local procedure ClearCopyItemParameters()
    var
        CopyItemParameters: Record "Copy Item Parameters";
    begin
        CopyItemParameters.DeleteAll();
    end;

    local procedure CreateBOMComponent(Item: Record Item; ParentItemNo: Code[20]; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ParentItemNo, BOMComponent.Type::Item, Item."No.", QuantityPer, Item."Base Unit of Measure");
    end;

    local procedure CreateDefaultDimensionForItem(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateSeveralDefaultDimensionsForItem(ItemNo: Code[20]; NoOfDims: Integer)
    var
        DimensionValue: Record "Dimension Value";
        DefaultDimension: Record "Default Dimension";
        i: Integer;
    begin
        for i := 1 to NoOfDims do begin
            LibraryDimension.CreateDimWithDimValue(DimensionValue);
            LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, DimensionValue."Dimension Code", DimensionValue.Code);
        end;
    end;

    local procedure CreateExtendedText(var ExtendedTextLine: Record "Extended Text Line"; ItemNo: Code[20])
    var
        ExtendedTextHeader: Record "Extended Text Header";
    begin
        LibraryInventory.CreateExtendedTextHeaderItem(ExtendedTextHeader, ItemNo);
        LibraryInventory.CreateExtendedTextLineItem(ExtendedTextLine, ExtendedTextHeader);
    end;

    local procedure CreateItemAttributeMappedToItem(ItemNo: Code[20])
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        LibraryInventory.CreateItemAttributeValue(
          ItemAttributeValue, ItemAttribute.ID,
          CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(ItemAttributeValue.Value)), 1, MaxStrLen(ItemAttributeValue.Value)));
        LibraryInventory.CreateItemAttributeValueMapping(DATABASE::Item, ItemNo, ItemAttribute.ID, ItemAttributeValue.ID);
    end;

    local procedure CreateItemCommentLine(ItemNo: Code[20]): Text[80]
    var
        CommentLine: Record "Comment Line";
    begin
        LibraryFixedAsset.CreateCommentLine(CommentLine, CommentLine."Table Name"::Item, ItemNo);
        CommentLine.Validate(Comment, LibraryUtility.GenerateGUID());
        CommentLine.Modify(true);
        exit(CommentLine.Comment);
    end;

    local procedure CreateItemTranslation(ItemNo: Code[20]) Description: Text[50]
    var
        ItemCard: TestPage "Item Card";
        ItemTranslations: TestPage "Item Translations";
        LibraryERM: Codeunit "Library - ERM";
    begin
        Description := LibraryUtility.GenerateGUID();
        ItemCard.OpenEdit();
        ItemTranslations.Trap();
        ItemCard.FILTER.SetFilter("No.", ItemNo);
        ItemCard.Translations.Invoke();
        ItemTranslations."Language Code".SetValue(LibraryERM.GetAnyLanguageDifferentFromCurrent());
        ItemTranslations.Description.SetValue(Description);
        ItemTranslations.OK().Invoke();
    end;

    local procedure CreateItemTranslationWithRecord(ItemNo: Code[20]; LanguageCode: Code[10]): Text[50]
    var
        ItemTranslation: Record "Item Translation";
    begin
        ItemTranslation.Init();
        ItemTranslation.Validate("Item No.", ItemNo);
        ItemTranslation.Validate("Language Code", LanguageCode);
        ItemTranslation.Validate(Description, ItemNo + LanguageCode);
        ItemTranslation.Insert(true);
        exit(ItemTranslation.Description);
    end;

    local procedure CreateItemWithCommentLine(var Item: Record Item) Comment: Text[80]
    begin
        LibraryInventory.CreateItem(Item);
        Comment := CreateItemCommentLine(Item."No.");
    end;

    local procedure CreateItemWithSeveralCommentLines(var Item: Record Item; var Comments: array[3] of Text)
    var
        i: Integer;
    begin
        LibraryInventory.CreateItem(Item);
        for i := 1 to ArrayLen(Comments) do
            Comments[i] := CreateItemCommentLine(Item."No.");
    end;

    local procedure CreateResourceSkill(var ResourceSkill: Record "Resource Skill"; ItemNo: Code[20])
    var
        SkillCode: Record "Skill Code";
    begin
        LibraryResource.CreateSkillCode(SkillCode);
        LibraryResource.CreateResourceSkill(ResourceSkill, ResourceSkill.Type::Item, ItemNo, SkillCode.Code);
    end;

    local procedure CreatePurchasePriceWithLineDiscount(var PurchasePrice: Record "Purchase Price"; var PurchaseLineDiscount: Record "Purchase Line Discount"; Item: Record Item)
    begin
        LibraryCosting.CreatePurchasePrice(
          PurchasePrice, LibraryPurchase.CreateVendorNo(), Item."No.", WorkDate(), '', '', Item."Base Unit of Measure",
          LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateLineDiscForVendor(
          PurchaseLineDiscount, Item."No.", PurchasePrice."Vendor No.", WorkDate(), '', '', Item."Base Unit of Measure",
          LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateSalesPriceWithLineDiscount(var SalesPrice: Record "Sales Price"; var SalesLineDiscount: Record "Sales Line Discount"; Item: Record Item)
    begin
        LibraryCosting.CreateSalesPrice(
          SalesPrice, SalesPrice."Sales Type"::Customer, LibrarySales.CreateCustomerNo(), Item."No.", WorkDate(),
          '', '', Item."Base Unit of Measure", LibraryRandom.RandDec(10, 2));
        LibraryERM.CreateLineDiscForCustomer(
          SalesLineDiscount, SalesLineDiscount.Type::Item, Item."No.", SalesLineDiscount."Sales Type"::Customer,
          SalesPrice."Sales Code", WorkDate(), '', '', Item."Base Unit of Measure", LibraryRandom.RandDec(10, 2));
    end;

    local procedure CreateTroubleshootingHeader(var TroubleshootingHeader: Record "Troubleshooting Header")
    begin
        TroubleshootingHeader.Init();
        TroubleshootingHeader."No." :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(TroubleshootingHeader.FieldNo("No."), DATABASE::"Troubleshooting Header"),
            1,
            MaxStrLen(TroubleshootingHeader."No."));
        TroubleshootingHeader.Insert(true);
    end;

    local procedure CreateTroubleShootingSetup(var TroubleshootingSetup: Record "Troubleshooting Setup"; ItemNo: Code[20])
    var
        TroubleshootingHeader: Record "Troubleshooting Header";
    begin
        CreateTroubleshootingHeader(TroubleshootingHeader);
        LibraryService.CreateTroubleshootingSetup(
          TroubleshootingSetup, TroubleshootingSetup.Type::Item, ItemNo, TroubleshootingHeader."No.");
    end;

    local procedure CreateUniqItemNoSeries(): Code[10]
    var
        InventorySetup: Record "Inventory Setup";
        NoSeries: Record "No. Series";
        NoSeriesLine: Record "No. Series Line";
        NumberBase: Code[5];
    begin
        NumberBase := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(5, 0), 1, MaxStrLen(NumberBase));
        LibraryUtility.CreateNoSeries(NoSeries, true, true, false);
        LibraryUtility.CreateNoSeriesLine(NoSeriesLine, NoSeries.Code, NumberBase + '00001', NumberBase + '99999');

        InventorySetup.Get();
        LibraryNoSeries.CreateNoSeriesRelationship(InventorySetup."Item Nos.", NoSeries.Code);
        exit(NoSeries.Code);
    end;

    local procedure CreateStandardSalesLinesWithItemForCustomer(var StandardSalesLine: Record "Standard Sales Line"; var StandardCustomerSalesCode: Record "Standard Customer Sales Code")
    var
        StandardSalesCode: Record "Standard Sales Code";
        Customer: Record Customer;
    begin
        LibrarySales.CreateStandardSalesCode(StandardSalesCode);

        LibrarySales.CreateStandardSalesLine(StandardSalesLine, StandardSalesCode.Code);
        StandardSalesLine.Type := StandardSalesLine.Type::Item;
        StandardSalesLine.Quantity := LibraryRandom.RandInt(10);
        StandardSalesLine."No." := LibraryInventory.CreateItemNo();
        StandardSalesLine.Modify();

        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateCustomerSalesCode(StandardCustomerSalesCode, Customer."No.", StandardSalesCode.Code);
    end;

    local procedure CreateStandardPurchaseLinesWithItemForVendor(var StandardPurchaseLine: Record "Standard Purchase Line"; var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code")
    var
        StandardPurchaseCode: Record "Standard Purchase Code";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);

        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code);
        StandardPurchaseLine.Type := StandardPurchaseLine.Type::Item;
        StandardPurchaseLine.Quantity := LibraryRandom.RandInt(10);
        StandardPurchaseLine."No." := LibraryInventory.CreateItemNo();
        StandardPurchaseLine.Modify();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseCode.Code);
    end;

    local procedure CopyItem(ItemNo: Code[20])
    var
        ItemCard: TestPage "Item Card";
    begin
        ItemCard.OpenEdit();
        ItemCard.FILTER.SetFilter("No.", ItemNo);
        Commit();  // COMMIT is required to handle Item Copy  page.
        ItemCard.CopyItem.Invoke();
    end;

    local procedure CopyItemOnItemListPage(ItemNo: Code[20])
    var
        ItemList: TestPage "Item List";
    begin
        ItemList.OpenEdit();
        ItemList.FILTER.SetFilter("No.", ItemNo);
        Commit();  // COMMIT is required to handle Item Copy  page.
        ItemList.CopyItem.Invoke();
    end;

    local procedure EnqueueValuesForCopyItemPageHandler(CopyItemBuffer: Record "Copy Item Buffer")
    begin
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Target Item No.");
        LibraryVariableStorage.Enqueue(CopyItemBuffer.Comments);
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Units of Measure");
        LibraryVariableStorage.Enqueue(CopyItemBuffer.Translations);
        LibraryVariableStorage.Enqueue(CopyItemBuffer.Dimensions);
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Item Variants");
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Extended Texts");
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Resource Skills");
        LibraryVariableStorage.Enqueue(CopyItemBuffer.Troubleshooting);
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Sales Line Discounts");
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Sales Prices");
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Purchase Line Discounts");
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Purchase Prices");
        LibraryVariableStorage.Enqueue(CopyItemBuffer."BOM Components");
    end;

    local procedure VerifyBOMComponent(ParentItemNo: Code[20]; ItemNo: Code[20]; QuantityPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.SetRange("No.", ItemNo);
        BOMComponent.FindFirst();
        BOMComponent.TestField("Quantity per", QuantityPer);
    end;

    local procedure VerifyCommentLine(ItemNo: Code[20]; Comment: Text[80])
    var
        CommentLine: Record "Comment Line";
    begin
        CommentLine.SetRange("Table Name", CommentLine."Table Name"::Item);
        CommentLine.SetRange("No.", ItemNo);
        CommentLine.FindFirst();
        CommentLine.TestField(Comment, Comment);
    end;

    local procedure VerifyExtendedText(ExtendedTextLine: Record "Extended Text Line"; ItemNo: Code[20])
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine2: Record "Extended Text Line";
    begin
        ExtendedTextHeader.Get(ExtendedTextLine."Table Name", ItemNo, ExtendedTextLine."Language Code", ExtendedTextLine."Text No.");
        ExtendedTextLine2.Get(
          ExtendedTextHeader."Table Name", ItemNo, ExtendedTextHeader."Language Code", ExtendedTextHeader."Text No.",
          ExtendedTextLine."Line No.");
    end;

    local procedure VerifyPurchasePrice(PurchasePrice: Record "Purchase Price"; ItemNo: Code[20])
    var
        PurchasePrice2: Record "Purchase Price";
    begin
        PurchasePrice2.SetRange("Item No.", ItemNo);
        PurchasePrice2.SetRange("Vendor No.", PurchasePrice."Vendor No.");
        PurchasePrice2.FindFirst();
        PurchasePrice2.TestField("Minimum Quantity", PurchasePrice."Minimum Quantity");
    end;

    local procedure VerifyPurchaseLineDiscount(PurchaseLineDiscount: Record "Purchase Line Discount"; ItemNo: Code[20])
    begin
        PurchaseLineDiscount.SetRange("Item No.", ItemNo);
        PurchaseLineDiscount.SetRange("Vendor No.", PurchaseLineDiscount."Vendor No.");
        PurchaseLineDiscount.FindFirst();
        PurchaseLineDiscount.TestField("Minimum Quantity", PurchaseLineDiscount."Minimum Quantity");
    end;

    local procedure VerifySalesLineDiscount(ItemNo: Code[20]; LineDiscount: Decimal)
    var
        SalesLineDiscount: Record "Sales Line Discount";
    begin
        SalesLineDiscount.SetRange(Type, SalesLineDiscount.Type::Item);
        SalesLineDiscount.SetRange(Code, ItemNo);
        SalesLineDiscount.FindFirst();
        SalesLineDiscount.TestField("Line Discount %", LineDiscount);
    end;

    local procedure VerifySalesPrice(SalesPrice: Record "Sales Price"; ItemNo: Code[20])
    var
        SalesPrice2: Record "Sales Price";
    begin
        SalesPrice2.SetRange("Item No.", ItemNo);
        SalesPrice2.SetRange("Sales Type", SalesPrice."Sales Type"::Customer);
        SalesPrice2.SetRange("Sales Code", SalesPrice."Sales Code");
        SalesPrice2.FindFirst();
        SalesPrice2.TestField("Minimum Quantity", SalesPrice."Minimum Quantity");
    end;

    local procedure VerifyItemGeneralInformation(ItemNo: Code[20]; Description: Text[100])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.TestField(Description, Description);
    end;

    local procedure VerifyItemTranslation(ItemNo: Code[20]; Description: Text[50])
    var
        ItemTranslation: Record "Item Translation";
    begin
        ItemTranslation.SetRange("Item No.", ItemNo);
        ItemTranslation.FindFirst();
        ItemTranslation.TestField(Description, Description);
    end;

    local procedure VerifyItemUnitOfMeasure(ItemNo: Code[20]; UoMCode: Code[10])
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        ItemUnitOfMeasure.SetRange("Item No.", ItemNo);
        ItemUnitOfMeasure.SetRange(Code, UoMCode);
        Assert.RecordCount(ItemUnitOfMeasure, 1);
    end;

    local procedure VerifyItemVariant(ItemVariant: Record "Item Variant"; ItemNo: Code[20])
    begin
        ItemVariant.Get(ItemNo, ItemVariant.Code);
        ItemVariant.TestField(Code, ItemVariant.Code);
        ItemVariant.TestField(Description, ItemVariant.Description);
    end;

    local procedure VerifyDefaultDimension(DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    begin
        DefaultDimension.Get(DefaultDimension."Table ID", ItemNo, DefaultDimension."Dimension Code");
        DefaultDimension.TestField("Dimension Code", DefaultDimension."Dimension Code");
        DefaultDimension.TestField("Dimension Value Code", DefaultDimension."Dimension Value Code");
    end;

    local procedure VerifyItemAttributes(SourceItemNo: Code[20]; TargetItemNo: Code[20])
    var
        SourceItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        TargetItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        SourceItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        SourceItemAttributeValueMapping.SetRange("No.", SourceItemNo);

        TargetItemAttributeValueMapping.SetRange("Table ID", DATABASE::Item);
        TargetItemAttributeValueMapping.SetRange("No.", TargetItemNo);

        Assert.AreEqual(SourceItemAttributeValueMapping.Count, TargetItemAttributeValueMapping.Count, NoOfRecordsMismatchErr);

        SourceItemAttributeValueMapping.FindSet();
        repeat
            TargetItemAttributeValueMapping.Get(DATABASE::Item, TargetItemNo, SourceItemAttributeValueMapping."Item Attribute ID");
            TargetItemAttributeValueMapping.TestField("Item Attribute Value ID", SourceItemAttributeValueMapping."Item Attribute Value ID");
        until SourceItemAttributeValueMapping.Next() = 0;
    end;

    local procedure VerifyPriceListLines(PriceListLine: array[6] of Record "Price List Line"; NewItemNo: Code[20])
    var
        NewPriceListLine: Record "Price List Line";
        i: Integer;
    begin
        for i := 1 to ArrayLen(PriceListLine) do begin
            NewPriceListLine.SetRange("Price List Code", PriceListLine[i]."Price List Code");
            NewPriceListLine.SetRange("Amount Type", PriceListLine[i]."Amount Type");
            NewPriceListLine.SetRange("Asset No.", NewItemNo);
            Assert.IsTrue(NewPriceListLine.FindFirst(), 'not found a new line #' + format(i));
            NewPriceListLine.TestField("Minimum Quantity", PriceListLine[i]."Minimum Quantity");
            NewPriceListLine.TestField("Unit Price", PriceListLine[i]."Unit Price");
            NewPriceListLine.TestField("Line Discount %", PriceListLine[i]."Line Discount %");
            Assert.IsTrue(NewPriceListLine.Next() = 0, 'found another line for line #' + format(i));
        end;
    end;

    local procedure CreateStandardPurchaseLinesWithGLForVendor(
        var StandardPurchaseLine: Record "Standard Purchase Line";
        var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code";
        PurchaseLineType: Enum "Purchase Line Type")
    var
        Vendor: Record Vendor;
        StandardPurchaseCode: Record "Standard Purchase Code";
    begin
        LibraryPurchase.CreateStandardPurchaseCode(StandardPurchaseCode);

        LibraryPurchase.CreateStandardPurchaseLine(StandardPurchaseLine, StandardPurchaseCode.Code);
        StandardPurchaseLine.Validate(Type, PurchaseLineType);
        StandardPurchaseLine.Validate("No.", LibraryERM.CreateGLAccountWithPurchSetup());
        StandardPurchaseLine.Validate(Quantity, LibraryRandom.RandInt(10));
        StandardPurchaseLine.Modify();

        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreateVendorPurchaseCode(StandardVendorPurchaseCode, Vendor."No.", StandardPurchaseCode.Code);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        CopyItem.TargetItemNo.SetValue(LibraryVariableStorage.DequeueText());
        CopyItem.GeneralItemInformation.SetValue(true);
        CopyItem.Comments.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.UnitsOfMeasure.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.Translations.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.Dimensions.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.ItemVariants.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.ExtendedTexts.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.Troubleshooting.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.ResourceSkills.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.SalesLineDisc.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.SalesPrices.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.PurchaseLineDisc.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.PurchasePrices.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.BOMComponents.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemAttributesPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        CopyItem.TargetItemNo.SetValue(LibraryVariableStorage.DequeueText());
        CopyItem.GeneralItemInformation.SetValue(true);
        CopyItem.Attributes.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemNumberOfEntriesPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        CopyItem.NumberOfCopies.SetValue(LibraryVariableStorage.DequeueInteger());
        CopyItem.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemItemReferencesPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        CopyItem.ItemReferences.SetValue(true);
        CopyItem.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemNumberOfEntriesTargetNoPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        CopyItem.TargetItemNo.SetValue(LibraryVariableStorage.DequeueText());
        CopyItem.NumberOfCopies.SetValue(LibraryVariableStorage.DequeueInteger());
        CopyItem.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemGetTargetItemNosPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        LibraryVariableStorage.Enqueue(CopyItem.TargetNoSeries.Value);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemSetTargetItemNosPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        CopyItem.TargetNoSeries.AssistEdit();
        CopyItem.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalItemCardHandler(var ItemCard: TestPage "Item Card")
    begin
        LibraryVariableStorage.Enqueue(ItemCard."No.".Value);
    end;


    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ModalItemListHandler(var ItemList: TestPage "Item List")
    begin
        LibraryVariableStorage.Enqueue(ItemList.FILTER.GetFilter("No."));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure NoSeriesListModalPageHandler(var NoSeriesList: TestPage "No. Series")
    begin
        NoSeriesList.FILTER.SetFilter(Code, LibraryVariableStorage.DequeueText());
        NoSeriesList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemCheckCommentsAndUnitOfMeasurePageHandler(var CopyItem: TestPage "Copy Item")
    begin
        LibraryVariableStorage.Enqueue(CopyItem.Comments.AsBoolean());
        LibraryVariableStorage.Enqueue(CopyItem.UnitsOfMeasure.AsBoolean());
        CopyItem.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemCheckSourceItemNoPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        LibraryVariableStorage.Enqueue(CopyItem.SourceItemNo.Value);
        CopyItem.Cancel().Invoke();
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure ShowCreatedItemsSendNotificationHandler(var Notification: Notification): Boolean
    var
        CopyItem: Codeunit "Copy Item";
    begin
        CopyItem.ShowCreatedItems(Notification);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure CopyItemWithoutGeneralInformationPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        CopyItem.TargetItemNo.SetValue(LibraryVariableStorage.DequeueText());
        CopyItem.GeneralItemInformation.SetValue(false);
        CopyItem.Comments.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.UnitsOfMeasure.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.Translations.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.Dimensions.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.ItemVariants.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.ExtendedTexts.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.Troubleshooting.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.ResourceSkills.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.SalesLineDisc.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.SalesPrices.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.PurchaseLineDisc.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.PurchasePrices.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.BOMComponents.SetValue(LibraryVariableStorage.DequeueBoolean());
        CopyItem.OK().Invoke();
    end;
}
