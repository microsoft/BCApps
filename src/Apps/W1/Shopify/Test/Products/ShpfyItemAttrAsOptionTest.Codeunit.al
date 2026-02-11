// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using System.TestLibraries.Utilities;

/// <summary>
/// Codeunit Shpfy Item Attr As Option Test (ID 139540).
/// Tests for 'Item Attributes As Shopify Product Options' functionality.
/// </summary>
codeunit 139596 "Shpfy Item Attr As Option Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestHttpRequestPolicy = BlockOutboundRequests;
    TestPermissions = Disabled;

    var
        Shop: Record "Shpfy Shop";
        Any: Codeunit Any;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        HttpHandlerParams: Codeunit "Library - Variable Storage";
        OutboundHttpRequests: Codeunit "Library - Variable Storage";
        LibraryAssert: Codeunit "Library Assert";
        LibraryInventory: Codeunit "Library - Inventory";
        InitializeTest: Codeunit "Shpfy Initialize Test";
        IsInitialized: Boolean;
        UnexpectedAPICallsErr: Label 'More than expected API calls to Shopify detected.';

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    #region UoM as Variant validation Tests
    [Test]
    procedure UnitTestValidateUoMAsVariantWhenAsOptionAttributesExist()
    var
        ItemAttribute: Record "Item Attribute";
        FailureMessageErr: Label 'You cannot enable this setting because one or more Item Attributes are configured with "Incl. in Product Sync" set to "As Option".';
        ExpectedErrorNotRaisedErr: Label 'Expected error was not raised.';
    begin
        // [SCENARIO] Enabling 'UoM as Variant' fails when 'As Option' Item Attributes exist

        // [GIVEN] Shopify Shop is created, and UoM as Variant is false
        Initialize();

        // [GIVEN] Some Item Attributes are marked 'As Option'
        CreateItemAttributeAsOption(ItemAttribute);

        // [WHEN] User tries to validate 'UoM as Variant' to true
        asserterror Shop.Validate("UoM as Variant", true);

        // [THEN] Error is raised about unavailability
        LibraryAssert.IsTrue(GetLastErrorText().Contains(FailureMessageErr), ExpectedErrorNotRaisedErr);
    end;
    #endregion

    #region No Variants, No As Option Attributes
    [Test]
    procedure UnitTestExportItemWithoutVariantsAndWithoutAsOptionAttributes()
    var
        Item: Record Item;
        TempShopifyProduct: Record "Shpfy Product" temporary;
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        TempTag: Record "Shpfy Tag" temporary;
        CreateProduct: Codeunit "Shpfy Create Product";
    begin
        // [SCENARIO] Exporting Item without variants and without 'As Option' attributes creates Shopify product variant with no options

        // [GIVEN] Shopify Shop is created
        Initialize();
        CreateProduct.SetShop(Shop);

        // [GIVEN] Item is created without Item variants and without 'As Option' Item Attributes
        CreateItem(Item);

        // [WHEN] Create Temp Product from Item
        CreateProduct.CreateTempProduct(Item, TempShopifyProduct, TempShopifyVariant, TempTag);

        // [THEN] Product variant is created without Option Names and Option values
        VerifyVariantHasNoOptions(TempShopifyVariant);
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler_GetProductOptions')]
    procedure UnitTestAddItemAsVariantToProductWithoutAsOptionAttributes()
    var
        Item: Record Item;
        CreateItemAsVariant: Codeunit "Shpfy Create Item As Variant";
        ParentProductId: BigInteger;
        ProdOptionNameTok: Label 'Variant', Locked = true;
    begin
        // [SCENARIO] Adding Item as variant to product without 'As Option' attributes creates variant with 'Variant' option

        // [GIVEN] Shopify Shop is created
        Initialize();
        RegisterOutboundHttpRequests();
        HttpHandlerParams.Enqueue(ProdOptionNameTok);

        // [GIVEN] Product exists without As Option Attributes
        ParentProductId := CreateShopifyProductWithoutAsOptionAttributes();

        // [GIVEN] Item is created without Item variants and without 'As Option' Item Attributes
        CreateItem(Item);

        // [WHEN] Add Item as Shopify Variant
        CreateItemAsVariant.SetParentProduct(ParentProductId);
        CreateItemAsVariant.CheckProductAndShopSettings();
        CreateItemAsVariant.CreateVariantFromItem(Item);

        // [THEN] New Variant is created with Option 1 Name 'Variant', Option 1 Value '<Item No.>'
        VerifyVariantCreatedWithItemNo(ParentProductId, Item."No.");
    end;

    #endregion

    #region No Variants, 2 As Option Attributes
    [Test]
    procedure UnitTestExportItemWithoutVariantsAndWith2AsOptionAttributes()
    var
        Item: Record Item;
        TempShopifyProduct: Record "Shpfy Product" temporary;
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        TempTag: Record "Shpfy Tag" temporary;
        CreateProduct: Codeunit "Shpfy Create Product";
    begin
        // [SCENARIO] Exporting Item without variants but with 2 'As Option' attributes creates variant with 2 options

        // [GIVEN] Shopify Shop is created
        Initialize();
        CreateProduct.SetShop(Shop);

        // [GIVEN] Item is created without Item variants but with 2 'As Option' Item Attributes
        Item := CreateItemWithAsOptionAttributes(2);

        // [WHEN] Create Temp Product from Item
        CreateProduct.CreateTempProduct(Item, TempShopifyProduct, TempShopifyVariant, TempTag);

        // [THEN] Product variant is created with Item attributes as options
        VerifyVariantHas2Options(TempShopifyVariant);

        // [THEN] Product should be marked as having variants
        VerifyProductHasVariants(TempShopifyProduct);
    end;

    [Test]
    procedure UnitTestValidateItemAttributesForNewVariantMissingAttributes()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ProductExport: Codeunit "Shpfy Product Export";
        ValidationResult: Boolean;
        ExpFailureMessageErr: Label 'cannot be added as a product variant because it does not have required attributes.';
        ParentProductId: BigInteger;
    begin
        // [SCENARIO] Adding Item as variant fails when Item is missing required 'As Option' attributes

        // [GIVEN] Shopify Shop is created
        Initialize();
        ProductExport.SetShop(Shop);

        // [GIVEN] Item is created without Item variants but with 2 'As Option' Item Attributes
        Item := CreateItemWithAsOptionAttributes(2);

        // [GIVEN] Product exists with 'As Option' Attributes
        ParentProductId := CreateShopifyProductWithAsOptionAttributesAndValues(Item, CopyStr(LibraryVariableStorage.PeekText(2), 1, 250), CopyStr(LibraryVariableStorage.PeekText(4), 1, 250), CopyStr(LibraryVariableStorage.PeekText(6), 1, 250), CopyStr(LibraryVariableStorage.PeekText(8), 1, 250));

        // [GIVEN] Item is created without Item variants and without all required 'As Option' Item Attributes
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        Item := CreateItemWithSpecificAsOptionAttributes(LibraryVariableStorage.PeekInteger(1), LibraryVariableStorage.PeekInteger(3), CopyStr(LibraryVariableStorage.PeekText(4), 1, 250), ItemAttribute.ID, 0, GenerateRandomAttributeValue());

        // [WHEN] Validate item attributes for new variant
        TempShopifyVariant.Init();
        ValidationResult := ProductExport.ValidateItemAttributesAsProductOptionsForNewVariant(TempShopifyVariant, Item, '', ParentProductId);

        // [THEN] Returns false (variant should not be created) and skipped entry is logged
        VerifyItemAttributesValidationForNewVariantFailed(ValidationResult);
        VerifySkippedEntryExists(Item.RecordId, ExpFailureMessageErr);
    end;

    [Test]
    procedure UnitTestValidateItemAttributesForNewVariantDuplicateCombination()
    var
        Item: Record Item;
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ProductExport: Codeunit "Shpfy Product Export";
        ValidationResult: Boolean;
        ExpFailureMessageErr: Label 'cannot be added as a product variant because another variant already has the same option values.';
        ParentProductId: BigInteger;
    begin
        // [SCENARIO] Adding Item as variant fails when option value combination already exists

        // [GIVEN] Shopify Shop is created
        Initialize();
        ProductExport.SetShop(Shop);

        // [GIVEN] Item is created without Item variants but with 2 'As Option' Item Attributes
        Item := CreateItemWithAsOptionAttributes(2);

        // [GIVEN] Product exists with 'As Option' Attributes
        ParentProductId := CreateShopifyProductWithAsOptionAttributesAndValues(Item, CopyStr(LibraryVariableStorage.PeekText(2), 1, 250), CopyStr(LibraryVariableStorage.PeekText(4), 1, 250), CopyStr(LibraryVariableStorage.PeekText(6), 1, 250), CopyStr(LibraryVariableStorage.PeekText(8), 1, 250));

        // [GIVEN] Item is created with the same 'As Option' Item Attribute values as existing variant
        Item := CreateItemWithSpecificAsOptionAttributes(LibraryVariableStorage.PeekInteger(1), LibraryVariableStorage.PeekInteger(3), CopyStr(LibraryVariableStorage.PeekText(4), 1, 250), LibraryVariableStorage.PeekInteger(5), LibraryVariableStorage.PeekInteger(7), CopyStr(LibraryVariableStorage.PeekText(8), 1, 250));

        // [WHEN] Validate item attributes for new variant
        TempShopifyVariant.Init();
        ValidationResult := ProductExport.ValidateItemAttributesAsProductOptionsForNewVariant(TempShopifyVariant, Item, '', ParentProductId);

        // [THEN] Returns false (variant should not be created) and skipped entry is logged
        VerifyItemAttributesValidationForNewVariantFailed(ValidationResult);
        VerifySkippedEntryExists(Item.RecordId, ExpFailureMessageErr);
    end;

    [Test]
    [HandlerFunctions('HttpSubmitHandler_GetProductOptions')]
    procedure UnitTestAddItemAsVariantToProductWithAsOptionAttributes()
    var
        Item: Record Item;
        ProductExport: Codeunit "Shpfy Product Export";
        CreateItemAsVariant: Codeunit "Shpfy Create Item As Variant";
        ParentProductId: BigInteger;
    begin
        // [SCENARIO] Item variant is successfully created for the product when Item attributes differs

        // [GIVEN] Shopify Shop is created
        Initialize();
        ProductExport.SetShop(Shop);
        RegisterOutboundHttpRequests();

        // [GIVEN] Item is created without Item variants but with 2 'As Option' Item Attributes
        Item := CreateItemWithAsOptionAttributes(2);
        HttpHandlerParams.Enqueue(LibraryVariableStorage.PeekText(2));

        // [GIVEN] Product exists with 'As Option' Attributes
        ParentProductId := CreateShopifyProductWithAsOptionAttributesAndValues(Item, CopyStr(LibraryVariableStorage.PeekText(2), 1, 250), CopyStr(LibraryVariableStorage.PeekText(4), 1, 250), CopyStr(LibraryVariableStorage.PeekText(6), 1, 250), CopyStr(LibraryVariableStorage.PeekText(8), 1, 250));

        // [GIVEN] Item is created without Item variants and with all required 'As Option' Item Attributes
        Item := CreateItemWithSpecificAsOptionAttributes(LibraryVariableStorage.PeekInteger(1), LibraryVariableStorage.PeekInteger(3), CopyStr(LibraryVariableStorage.PeekText(4), 1, 250), LibraryVariableStorage.PeekInteger(5), LibraryVariableStorage.PeekInteger(7), GenerateRandomAttributeValue());

        // [WHEN] Add Item as Shopify Variant
        CreateItemAsVariant.SetParentProduct(ParentProductId);
        CreateItemAsVariant.CheckProductAndShopSettings();
        CreateItemAsVariant.CreateVariantFromItem(Item);

        // [THEN] New Variant is created with new combination of product options
        VerifyVariantCreatedWithCorrectOptionValues(ParentProductId);
    end;

    #endregion

    #region 2 Variants, No As Option Attributes
    [Test]
    procedure UnitTestExportItemWith2VariantsAndWithoutAsOptionAttributes()
    var
        Item: Record Item;
        TempShopifyProduct: Record "Shpfy Product" temporary;
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        TempTag: Record "Shpfy Tag" temporary;
        CreateProduct: Codeunit "Shpfy Create Product";
        ExpOptionNameTok: Label 'Variant', Locked = true;
    begin
        // [SCENARIO] Exporting Item with 2 variants and without 'As Option' attributes creates 2 variants with 'Variant' option name

        // [GIVEN] Shopify Shop is created
        Initialize();
        CreateProduct.SetShop(Shop);

        // [GIVEN] Item is created with 2 Item variants and without 'As Option' Item Attributes
        CreateItemWithVariants(Item, 2);

        // [WHEN] Create Temp Product from Item
        CreateProduct.CreateTempProduct(Item, TempShopifyProduct, TempShopifyVariant, TempTag);

        // [THEN] 2 Product variants are created (Option 1 Name for both 'Variant')
        VerifyVariantsCreatedWithOptionName(TempShopifyVariant, 2, ExpOptionNameTok);
    end;

    #endregion

    #region 2 Variants, 3 As Option Attributes
    [Test]
    procedure UnitTestExportItemWith2VariantsAnd3AsOptionAttributesDifferentCombinations()
    var
        Item: Record Item;
        TempShopifyProduct: Record "Shpfy Product" temporary;
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        TempTag: Record "Shpfy Tag" temporary;
        CreateProduct: Codeunit "Shpfy Create Product";
    begin
        // [SCENARIO] Exporting Item with 2 variants and 3 'As Option' attributes creates 2 variants with unique option combinations

        // [GIVEN] Shopify Shop is created
        Initialize();
        CreateProduct.SetShop(Shop);

        // [GIVEN] Item is created with 2 Item variants and 3 'As Option' Item Attributes with different value combinations
        Item := CreateItemWithVariantsAndAsOptionAttributes(2, 3, false);

        // [WHEN] Create Temp Product from Item
        CreateProduct.CreateTempProduct(Item, TempShopifyProduct, TempShopifyVariant, TempTag);

        // [THEN] 2 Product variants are created with different Item attribute combinations
        VerifyVariantsCreatedWith3Options(TempShopifyVariant, 2);

        // [THEN] Product should be marked as having variants
        VerifyProductHasVariants(TempShopifyProduct);
    end;

    [Test]
    procedure UnitTestExportItemWith2VariantsAnd3AsOptionAttributesDuplicateCombinations()
    var
        Item: Record Item;
        ProductExport: Codeunit "Shpfy Product Export";
        CompatibilityCheckResult: Boolean;
        ExpFailureMessageErr: Label 'duplicate item variant attribute value combinations';
    begin
        // [SCENARIO] Exporting Item with duplicate option value combinations fails with skipped entry

        // [GIVEN] Shopify Shop is created
        Initialize();
        ProductExport.SetShop(Shop);

        // [GIVEN] Item is created with 2 Item variants and 3 'As Option' Item Attributes with duplicate value combinations
        Item := CreateItemWithVariantsAndAsOptionAttributes(2, 3, true);

        // [WHEN] Check item attributes compatible for product options
        CompatibilityCheckResult := ProductExport.CheckItemAttributesCompatibleForProductOptions(Item);

        // [THEN] Returns false (product should not be created) and skipped entry is logged
        VerifyResultOfCompatibilityCheck(CompatibilityCheckResult);
        VerifySkippedEntryExists(Item.RecordId, ExpFailureMessageErr);
    end;

    [Test]
    procedure UnitTestExportItemWithMoreThan3AsOptionAttributes()
    var
        Item: Record Item;
        ProductExport: Codeunit "Shpfy Product Export";
        CompatibilityCheckResult: Boolean;
        ExpFailureMessageErr: Label 'maximum of 3 product options';
    begin
        // [SCENARIO] Exporting Item with more than 3 'As Option' attributes fails due to Shopify limit

        // [GIVEN] Shopify Shop is created
        Initialize();
        ProductExport.SetShop(Shop);

        // [GIVEN] Item is created without Item variants but with 4 'As Option' Item Attributes (exceeds Shopify limit of 3)
        Item := CreateItemWithAsOptionAttributes(4);

        // [WHEN] Check item attributes compatible for product options
        CompatibilityCheckResult := ProductExport.CheckItemAttributesCompatibleForProductOptions(Item);

        // [THEN] Returns false and skipped entry is logged about too many attributes
        VerifyResultOfCompatibilityCheck(CompatibilityCheckResult);
        VerifySkippedEntryExists(Item.RecordId, ExpFailureMessageErr);
    end;
    #endregion

    #region Helper Procedures
    local procedure Initialize()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        LibraryRandom: Codeunit "Library - Random";
        AccessToken: SecretText;
    begin
        LibraryVariableStorage.Clear();
        OutboundHttpRequests.Clear();
        HttpHandlerParams.Clear();
        Any.SetDefaultSeed();
        if IsInitialized then
            exit;

        Shop := InitializeTest.CreateShop();

        // Disable Event Mocking 
        CommunicationMgt.SetTestInProgress(false);
        //Register Shopify Access Token
        AccessToken := LibraryRandom.RandText(20);
        InitializeTest.RegisterAccessTokenForShop(Shop.GetStoreName(), AccessToken);
        Commit();
        IsInitialized := true;
    end;

    local procedure CreateItemAttributeAsOption(var ItemAttribute: Record "Item Attribute")
    begin
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, '');
        ItemAttribute."Shpfy Incl. in Product Sync" := "Shpfy Incl. in Product Sync"::"As Option";
        ItemAttribute.Modify(true);
    end;

    local procedure GenerateRandomAttributeValue(): Text[250]
    begin
        exit(CopyStr(Any.AlphanumericText(50), 1, 250));
    end;

    local procedure CreateItem(var Item: Record Item)
    var
        ProductInitTest: Codeunit "Shpfy Product Init Test";
        ItemTemplateCode: Code[20];
    begin
        ItemTemplateCode := Shop."Item Templ. Code";
        Item := ProductInitTest.CreateItem(ItemTemplateCode, Any.DecimalInRange(10, 100, 2), Any.DecimalInRange(100, 500, 2), false);
    end;

    local procedure CreateItemWithVariants(var Item: Record Item; NumberOfVariants: Integer)
    var
        ItemVariant: Record "Item Variant";
        Index: Integer;
    begin
        CreateItem(Item);

        for Index := 1 to NumberOfVariants do begin
            ItemVariant.Init();
            ItemVariant."Item No." := Item."No.";
            ItemVariant.Code := CopyStr(Any.AlphabeticText(MaxStrLen(ItemVariant.Code)), 1, MaxStrLen(ItemVariant.Code));
            ItemVariant.Description := CopyStr(Any.AlphabeticText(50), 1, MaxStrLen(ItemVariant.Description));
            ItemVariant.Insert(true);
        end;
    end;

    local procedure CreateItemWithAsOptionAttributes(NumberOfAsOptionAttributes: Integer) Item: Record Item
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        Index: Integer;
    begin
        CreateItem(Item);

        for Index := 1 to NumberOfAsOptionAttributes do begin
            CreateItemAttributeMappedToItem(Item, ItemAttribute, ItemAttributeValue);

            LibraryVariableStorage.Enqueue(ItemAttribute.ID);
            LibraryVariableStorage.Enqueue(ItemAttribute.Name);
            LibraryVariableStorage.Enqueue(ItemAttributeValue.ID);
            LibraryVariableStorage.Enqueue(ItemAttributeValue.Value);
        end;
    end;

    local procedure CreateItemWithVariantsAndAsOptionAttributes(NumberOfVariants: Integer; NumberOfAsOptionAttributes: Integer; CreateDuplicateCombinations: Boolean) Item: Record Item
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        FirstAttributeValue: Record "Item Attribute Value";
        ItemVariant: Record "Item Variant";
        IsFirstVariant: Boolean;
        Index: Integer;
    begin
        CreateItemWithVariants(Item, NumberOfVariants);

        for Index := 1 to NumberOfAsOptionAttributes do begin
            CreateItemAttributeAsOption(ItemAttribute);
            IsFirstVariant := true;

            ItemVariant.SetRange("Item No.", Item."No.");
            if ItemVariant.FindSet() then
                repeat
                    if CreateDuplicateCombinations then begin
                        if IsFirstVariant then begin
                            LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, GenerateRandomAttributeValue());
                            FirstAttributeValue := ItemAttributeValue;
                            IsFirstVariant := false;
                        end else
                            ItemAttributeValue := FirstAttributeValue;
                    end else
                        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, GenerateRandomAttributeValue());

                    LibraryInventory.CreateItemVariantAttributeValueMapping(Item."No.", ItemVariant.Code, ItemAttribute.ID, ItemAttributeValue.ID, Database::Item, Item."No.");

                    LibraryVariableStorage.Enqueue(ItemAttribute.Name);
                    LibraryVariableStorage.Enqueue(ItemAttributeValue.Value);
                until ItemVariant.Next() = 0;

            LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);
        end;
    end;

    local procedure CreateItemWithSpecificAsOptionAttributes(ItemAttributeID1: Integer; ItemAttributeValueID1: Integer; ItemAttributeValue1: Text[250]; ItemAttributeID2: Integer; ItemAttributeValueID2: Integer; ItemAttributeValue2: Text[250]) Item: Record Item
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        CreateItem(Item);

        if not ItemAttributeValue.Get(ItemAttributeID1, ItemAttributeValueID1) then begin
            LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttributeID1, ItemAttributeValue1);
            ItemAttributeValueID1 := ItemAttributeValue.ID;
        end;

        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttributeID1, ItemAttributeValueID1);

        if not ItemAttributeValue.Get(ItemAttributeID2, ItemAttributeValueID2) then begin
            LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttributeID2, ItemAttributeValue2);
            ItemAttributeValueID2 := ItemAttributeValue.ID;
        end;
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttributeID2, ItemAttributeValueID2);
    end;

    local procedure CreateShopifyProductWithoutAsOptionAttributes(): BigInteger
    var
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
    begin
        ShopifyProduct.Init();
        ShopifyProduct.Id := Any.IntegerInRange(10000, 99999);
        ShopifyProduct."Shop Code" := Shop.Code;
        ShopifyProduct.Title := CopyStr(Any.AlphabeticText(50), 1, MaxStrLen(ShopifyProduct.Title));
        ShopifyProduct.Insert(true);

        ShopifyVariant.Init();
        ShopifyVariant.Id := Any.IntegerInRange(10000, 99999);
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Shop Code" := Shop.Code;
        ShopifyVariant."Option 1 Name" := 'Variant';
        ShopifyVariant."Option 1 Value" := 'Default';
        ShopifyVariant.Insert(true);

        exit(ShopifyProduct.Id);
    end;

    local procedure CreateShopifyProductWithAsOptionAttributesAndValues(Item: Record Item; ItemAttributeName1: Text[250]; ItemAttributeValue1: Text[250]; ItemAttributeName2: Text[250]; ItemAttributeValue2: Text[250]): BigInteger
    var
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
    begin
        ShopifyProduct.Init();
        ShopifyProduct."Item SystemId" := Item.SystemId;
        ShopifyProduct.Id := Any.IntegerInRange(10000, 99999);
        ShopifyProduct."Shop Code" := Shop.Code;
        ShopifyProduct.Title := CopyStr(Any.AlphabeticText(50), 1, MaxStrLen(ShopifyProduct.Title));
        ShopifyProduct."Has Variants" := true;
        ShopifyProduct.Insert(true);

        ShopifyVariant.Init();
        ShopifyVariant.Id := Any.IntegerInRange(10000, 99999);
        ShopifyVariant."Product Id" := ShopifyProduct.Id;
        ShopifyVariant."Shop Code" := Shop.Code;
        ShopifyVariant."Option 1 Name" := CopyStr(ItemAttributeName1, 1, MaxStrLen(ShopifyVariant."Option 1 Name"));
        ShopifyVariant."Option 1 Value" := CopyStr(ItemAttributeValue1, 1, MaxStrLen(ShopifyVariant."Option 1 Value"));
        ShopifyVariant."Option 2 Name" := CopyStr(ItemAttributeName2, 1, MaxStrLen(ShopifyVariant."Option 2 Name"));
        ShopifyVariant."Option 2 Value" := CopyStr(ItemAttributeValue2, 1, MaxStrLen(ShopifyVariant."Option 2 Value"));
        ShopifyVariant.Insert(true);

        exit(ShopifyProduct.Id);
    end;

    local procedure VerifyVariantHasNoOptions(var TempShopifyVariant: Record "Shpfy Variant" temporary)
    var
        EmptyOptionName1Lbl: Label 'Option 1 Name should be empty';
        EmptyOptionName2Lbl: Label 'Option 2 Name should be empty';
        EmptyOptionValue1Lbl: Label 'Option 1 Value should be empty';
        EmptyOptionValue2Lbl: Label 'Option 2 Value should be empty';
    begin
        LibraryAssert.RecordIsNotEmpty(TempShopifyVariant);
        LibraryAssert.AreEqual('', TempShopifyVariant."Option 1 Name", EmptyOptionName1Lbl);
        LibraryAssert.AreEqual('', TempShopifyVariant."Option 1 Value", EmptyOptionValue1Lbl);
        LibraryAssert.AreEqual('', TempShopifyVariant."Option 2 Name", EmptyOptionName2Lbl);
        LibraryAssert.AreEqual('', TempShopifyVariant."Option 2 Value", EmptyOptionValue2Lbl);
    end;

    local procedure VerifyVariantCreatedWithItemNo(ParentProductId: BigInteger; ItemNo: Code[20])
    var
        ShpfyVariant: Record "Shpfy Variant";
        Option1NameMismatchMsg: Label 'Option 1 Name should be ''Variant''';
        Option1ValueShouldBeItemNoMsg: Label 'Option 1 Value should be Item No.';
    begin
#pragma warning disable AA0210
        ShpfyVariant.SetRange("Product Id", ParentProductId);
        ShpfyVariant.SetRange("Shop Code", Shop.Code);
#pragma warning restore AA0210
        ShpfyVariant.FindLast();
        LibraryAssert.AreEqual(HttpHandlerParams.PeekText(1), ShpfyVariant."Option 1 Name", Option1NameMismatchMsg);
        LibraryAssert.AreEqual(ItemNo, ShpfyVariant."Option 1 Value", Option1ValueShouldBeItemNoMsg);
    end;

    local procedure VerifyVariantCreatedWithCorrectOptionValues(ParentProductId: BigInteger)
    var
        ShpfyVariant: Record "Shpfy Variant";
        Option1NameMismatchMsg: Label 'Incorrect Option 1 Name';
        Option1ValueMismatchMsg: Label 'Incorrect Option 1 Value';
        Option2NameMismatchMsg: Label 'Incorrect Option 2 Name';
        Option2ValueMismatchMsg: Label 'Incorrect Option 2 Value';
    begin
#pragma warning disable AA0210
        ShpfyVariant.SetRange("Product Id", ParentProductId);
        ShpfyVariant.SetRange("Shop Code", Shop.Code);
#pragma warning restore AA0210
        ShpfyVariant.FindLast();
        LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(2), ShpfyVariant."Option 1 Name", Option1NameMismatchMsg);
        LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(4), ShpfyVariant."Option 1 Value", Option1ValueMismatchMsg);
        LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(6), ShpfyVariant."Option 2 Name", Option2NameMismatchMsg);
        LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(8), ShpfyVariant."Option 2 Value", Option2ValueMismatchMsg);
    end;

    local procedure VerifyVariantHas2Options(var TempShopifyVariant: Record "Shpfy Variant" temporary)
    var
        Option1NameMismatchMsg: Label 'Incorrect Option 1 Name';
        Option1ValueMismatchMsg: Label 'Incorrect Option 1 Value';
        Option2NameMismatchMsg: Label 'Incorrect Option 2 Name';
        Option2ValueMismatchMsg: Label 'Incorrect Option 2 Value';
    begin
        LibraryAssert.RecordIsNotEmpty(TempShopifyVariant);
        LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(2), TempShopifyVariant."Option 1 Name", Option1NameMismatchMsg);
        LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(4), TempShopifyVariant."Option 1 Value", Option1ValueMismatchMsg);
        LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(6), TempShopifyVariant."Option 2 Name", Option2NameMismatchMsg);
        LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(8), TempShopifyVariant."Option 2 Value", Option2ValueMismatchMsg);
    end;

    local procedure VerifyProductHasVariants(var TempShopifyProduct: Record "Shpfy Product" temporary)
    var
        ProductHasVariantsMsg: Label 'Product should be marked as having variants';
    begin
        LibraryAssert.IsTrue(TempShopifyProduct."Has Variants", ProductHasVariantsMsg);
    end;

    local procedure VerifyItemAttributesValidationForNewVariantFailed(ValidationResult: Boolean)
    var
        IncorrectValidationResultMsg: Label 'Validation result was incorrect.';
    begin
        LibraryAssert.IsFalse(ValidationResult, IncorrectValidationResultMsg);
    end;

    local procedure VerifyVariantsCreatedWithOptionName(var TempShopifyVariant: Record "Shpfy Variant" temporary; ExpectedCount: Integer; ExpectedOption1Name: Text)
    var
        Option1ValueNotEmptyMsg: Label 'Option 1 Value should not be empty';
        Option1NameAssertionMsg: Label 'Incorrect Option 1 Name';
        IncorrectVariantCountMsg: Label 'Incorect count of variants has been be created';
    begin
        LibraryAssert.AreEqual(ExpectedCount, TempShopifyVariant.Count(), IncorrectVariantCountMsg);
        TempShopifyVariant.FindSet();
        repeat
            LibraryAssert.AreEqual(ExpectedOption1Name, TempShopifyVariant."Option 1 Name", Option1NameAssertionMsg);
            LibraryAssert.AreNotEqual('', TempShopifyVariant."Option 1 Value", Option1ValueNotEmptyMsg);
        until TempShopifyVariant.Next() = 0;
    end;

    local procedure VerifyVariantsCreatedWith3Options(var TempShopifyVariant: Record "Shpfy Variant" temporary; ExpectedCount: Integer)
    var
        Option1NameMismatchMsg: Label 'Option 1 Name has incorrect value.';
        Option1ValueMismatchMsg: Label 'Option 1 Value has incorrect value.';
        Option2NameMismatchMsg: Label 'Option 2 Name has incorrect value.';
        Option2ValueMismatchMsg: Label 'Option 2 Value has incorrect value.';
        Option3NameMismatchMsg: Label 'Option 3 Name has incorrect value.';
        Option3ValueMismatchMsg: Label 'Option 3 Value has incorrect value.';
        ItemVariantNumber: Integer;
    begin
        LibraryAssert.AreEqual(ExpectedCount, TempShopifyVariant.Count(), Format(ExpectedCount) + ' variants should be created');
        TempShopifyVariant.FindSet();
        repeat
            ItemVariantNumber += 1;
            if ItemVariantNumber = 1 then begin
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(1), TempShopifyVariant."Option 1 Name", Option1NameMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(2), TempShopifyVariant."Option 1 Value", Option1ValueMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(5), TempShopifyVariant."Option 2 Name", Option2NameMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(6), TempShopifyVariant."Option 2 Value", Option2ValueMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(9), TempShopifyVariant."Option 3 Name", Option3NameMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(10), TempShopifyVariant."Option 3 Value", Option3ValueMismatchMsg);
            end;
            if ItemVariantNumber = 2 then begin
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(3), TempShopifyVariant."Option 1 Name", Option1NameMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(4), TempShopifyVariant."Option 1 Value", Option1ValueMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(7), TempShopifyVariant."Option 2 Name", Option2NameMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(8), TempShopifyVariant."Option 2 Value", Option2ValueMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(11), TempShopifyVariant."Option 3 Name", Option3NameMismatchMsg);
                LibraryAssert.AreEqual(LibraryVariableStorage.PeekText(12), TempShopifyVariant."Option 3 Value", Option3ValueMismatchMsg);
            end;
        until TempShopifyVariant.Next() = 0;
    end;

    local procedure VerifyResultOfCompatibilityCheck(CompatibilityCheckResult: Boolean)
    var
        IncorrectResultMsg: Label 'Incorrect result of compatibility check.';
    begin
        LibraryAssert.IsFalse(CompatibilityCheckResult, IncorrectResultMsg);
    end;

    local procedure VerifySkippedEntryExists(ExpectedRecordId: RecordId; ExpFailureMessage: Text)
    var
        SkippedRecord: Record "Shpfy Skipped Record";
    begin
        SkippedRecord.SetRange("Record ID", ExpectedRecordId);
        SkippedRecord.SetFilter("Skipped Reason", '*' + ExpFailureMessage + '*');
        LibraryAssert.RecordIsNotEmpty(SkippedRecord);
    end;

    local procedure CreateItemAttributeMappedToItem(var Item: Record Item; var ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value")
    begin
        CreateItemAttributeAsOption(ItemAttribute);

        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, GenerateRandomAttributeValue());
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);
    end;

    local procedure RegisterOutboundHttpRequests()
    var
        GqlProductOptionsLbl: Label 'GQL Product Options';
        VariantCreatedFromItemResponseLbl: Label 'GQL Prod. Variant Creation Response';
    begin
        OutboundHttpRequests.Enqueue(GqlProductOptionsLbl);
        OutboundHttpRequests.Enqueue(VariantCreatedFromItemResponseLbl);
    end;
    #endregion

    [HttpClientHandler]
    internal procedure HttpSubmitHandler_GetProductOptions(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ResponseText: Text;
        ProductOptionsResponseTok: Label 'Products/ProductOptionsResponse.txt', Locked = true;
        VariantCreatedFromItemResponseTok: Label 'Products/VariantCreatedFromItemResponse.txt', Locked = true;
    begin
        if not InitializeTest.VerifyRequestUrl(Request.Path, Shop."Shopify URL") then
            exit(true);

        case OutboundHttpRequests.Length() of
            2:
                ResponseText := StrSubstNo(NavApp.GetResourceAsText(ProductOptionsResponseTok, TextEncoding::UTF8), HttpHandlerParams.PeekText(1));
            1:
                ResponseText := NavApp.GetResourceAsText(VariantCreatedFromItemResponseTok, TextEncoding::UTF8);
            0:
                Error(UnexpectedAPICallsErr);
        end;

        Response.Content.WriteFrom(ResponseText);
        OutboundHttpRequests.DequeueText();
        exit(false);
    end;
}