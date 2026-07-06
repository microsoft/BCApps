// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
codeunit 137415 "SCM Item Variant Attributes"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    var
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        IsInitialized: Boolean;
        ValueMustBeEqualErr: Label '%1 must be equal to %2 in the %3.', Comment = '%1 = Field Caption , %2 = Expected Value, %3 = Table Caption';
        RenameUsedAttributeQst: Label 'This item attribute has been assigned to at least one item or item variant.\\Are you sure you want to rename it?';
        DeleteUsedAttributeQst: Label 'This item attribute has been assigned to at least one item or item variant.\\Are you sure you want to delete it?';
        DeleteUsedAttributeValueQst: Label 'This item attribute value has been assigned to at least one item or item variant.\\Are you sure you want to delete it?';
        RenameUsedAttributeValueQst: Label 'This item attribute value has been assigned to at least one item or item variant.\\Are you sure you want to rename it?';
        ReuseValueTranslationsQst: Label 'There are values and translations for item attribute ''%1''.\\Do you want to reuse them after changing the item attribute name to ''%2''?', Comment = '%1 - arbitrary name,%2 - arbitrary name';

    [Test]
    procedure ItemAttributesAreInheritedFromItemInItemVariant()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemVariant: Record "Item Variant";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        // [SCENARIO 335313] Verify that the Item Attributes are inherited when a Item Variant is created from Item.
        Initialize();

        // [GIVEN] Create an Item with a text attribute.
        CreateItemWithTextAttribute(Item, ItemAttribute, ItemAttributeValue, LibraryUtility.GenerateGUID());

        // [WHEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [THEN] Verify that the Item Variant Attribute Value Mapping inherited from the Item.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute.ID);
        Assert.RecordCount(ItemVariantAttributeValueMapping, 1);
        Assert.AreEqual(
            Database::Item,
            ItemVariantAttributeValueMapping."Inherited-From Table ID",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Table ID"), Database::Item, ItemVariantAttributeValueMapping.TableCaption()));
        Assert.AreEqual(
            Item."No.",
            ItemVariantAttributeValueMapping."Inherited-From Key Value",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Key Value"), Item."No.", ItemVariantAttributeValueMapping.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ItemAttributesAreUpdatedFromItemInItemVariantWhenActionIsExecuted()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
    begin
        // [SCENARIO 335313] Verify that the Item Variant Attribute Mapping is updated when the Item Attribute Value is remapped and the UpdateItemVariantAttributeFromItem action is executed.
        Initialize();

        // [GIVEN] Create an Item with a text attribute.
        CreateItemWithTextAttribute(Item, ItemAttribute, ItemAttributeValue, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a new Item Attribute Value and remap value on the Item.
        CreateAndUpdateItemAttributeValueMapping(ItemAttributeValueMapping, ItemAttributeValue, ItemAttribute.ID, Item."No.", LibraryUtility.GenerateGUID());

        // [WHEN] Update the Item Variant attributes from the Item.
        ItemAttributeManagement.UpdateItemVariantAttributeFromItem(Item."No.");

        // [THEN] Verify that the Item Variant Attribute Value Mapping is updated.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute.ID);
        Assert.RecordCount(ItemVariantAttributeValueMapping, 1);
        Assert.AreEqual(
            ItemAttributeValue.ID,
            ItemVariantAttributeValueMapping."Item Attribute Value ID",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Item Attribute Value ID"), ItemAttributeValue.ID, ItemVariantAttributeValueMapping.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ModifyItemAttributeValueListHandler')]
    procedure ItemVariantAttributeValueMappingRemainsSameWhenActionIsExecuted()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
    begin
        // [SCENARIO 335313] Verify that the Item Variant Attribute Value Mapping remains the same when the action is executed.
        Initialize();

        // [GIVEN] Create an Item with a text attribute.
        CreateItemWithTextAttribute(Item, ItemAttribute, ItemAttributeValue, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a new Item Variant Attribute Value and remap value on the Item Variant.
        CreateAndUpdateItemVariantAttributeValueMapping(ItemVariant, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] Create a new Item Attribute Value and remap value on the Item.
        CreateAndUpdateItemAttributeValueMapping(ItemAttributeValueMapping, ItemAttributeValue, ItemAttribute.ID, Item."No.", LibraryUtility.GenerateGUID());

        // [WHEN] Update the Item Variant attributes from the Item.
        ItemAttributeManagement.UpdateItemVariantAttributeFromItem(Item."No.");

        // [THEN] Verify that the Item Variant Attribute Value Mapping remains the same.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute.ID);
        Assert.AreEqual(
            0,
            ItemVariantAttributeValueMapping."Inherited-From Table ID",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Table ID"), 0, ItemVariantAttributeValueMapping.TableCaption()));
        Assert.AreEqual(
            '',
            ItemVariantAttributeValueMapping."Inherited-From Key Value",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Key Value"), '', ItemVariantAttributeValueMapping.TableCaption()));
    end;

    [Test]
    procedure ItemVariantAttributeValueMappingRemainsSameWhenActionIsNotExecuted()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariants: TestPage "Item Variants";
    begin
        // [SCENARIO 335313] Verify that the Item Variant Attribute Value Mapping remains the same when the action is not executed.
        Initialize();

        // [GIVEN] Create an Item with a text attribute.
        CreateItemWithTextAttribute(Item, ItemAttribute, ItemAttributeValue[1], LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a new Item Attribute Value and remap value on the Item.
        CreateAndUpdateItemAttributeValueMapping(ItemAttributeValueMapping, ItemAttributeValue[2], ItemAttribute.ID, Item."No.", LibraryUtility.GenerateGUID());

        // [WHEN] Open Item Variant.
        ItemVariants.OpenEdit();
        ItemVariants.GoToRecord(ItemVariant);

        // [THEN] Verify that the Item Variant Attribute Value Mapping remains the same.
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute.Name);
        ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[1].Value);
        ItemVariants.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ItemVariantAttributeMappingIsUpdatedWhenNewItemAttributeIsAdded()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: array[2] of Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        ItemVariantCard: TestPage "Item Variant Card";
    begin
        // [SCENARIO 335313] Verify that when a new Item Attribute is added to the Item, the Item Variant Attribute Mapping is updated after executing the UpdateItemVariantAttributeFromItem action.
        Initialize();

        // [GIVEN] Create an Item with a text attribute.
        CreateItemWithTextAttribute(Item, ItemAttribute[1], ItemAttributeValue[1], LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a new Item Attribute and Item Attribute Value, and map them to the Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[2], ItemAttribute[2].Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[2], ItemAttribute[2].ID, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[2].ID, ItemAttributeValue[2].ID);

        // [GIVEN] Update the Item Variant attributes from the Item.
        ItemAttributeManagement.UpdateItemVariantAttributeFromItem(Item."No.");

        // [WHEN] Open Item Variant.
        ItemVariantCard.OpenEdit();
        ItemVariantCard.GoToRecord(ItemVariant);

        // [THEN] Verify that the first Item Variant Attribute.
        ItemVariantCard.ItemAttributesFactbox.First();
        ItemVariantCard.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[1].Name);
        ItemVariantCard.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[1].Value);

        // [THEN] Verify that the second Item Attribute.
        ItemVariantCard.ItemAttributesFactbox.Next();
        ItemVariantCard.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[2].Name);
        ItemVariantCard.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[2].Value);
        ItemVariantCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ModifyItemAttributeValueListHandler')]
    procedure ExistingAttributesRemainUnaffectedWhenNewItemAttributesAreAdded()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: array[2] of Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        ItemVariantCard: TestPage "Item Variant Card";
        ExpectedAttributeValue: Text[250];
    begin
        // [SCENARIO 335313] Verify that when a new Item Attribute is added to the Item, the existing Item Variant Attribute Mappings remain unaffected after executing the UpdateItemVariantAttributeFromItem action.
        Initialize();

        // [GIVEN] Create an Item with a text attribute.
        CreateItemWithTextAttribute(Item, ItemAttribute[1], ItemAttributeValue[1], LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Generate expected Item Attribute Value.
        ExpectedAttributeValue := LibraryUtility.GenerateGUID();

        // [GIVEN] Create a new Item Variant Attribute Value and remap value on the Item Variant.
        CreateAndUpdateItemVariantAttributeValueMapping(ItemVariant, ItemAttribute[1].ID, ExpectedAttributeValue);

        // [GIVEN] Create a new Item Attribute and Item Attribute Value, and map them to the Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[2], ItemAttribute[2].Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[2], ItemAttribute[2].ID, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[2].ID, ItemAttributeValue[2].ID);

        // [GIVEN] Update the Item Variant attributes from the Item.
        ItemAttributeManagement.UpdateItemVariantAttributeFromItem(Item."No.");

        // [WHEN] Open Item Variant.
        ItemVariantCard.OpenEdit();
        ItemVariantCard.GoToRecord(ItemVariant);

        // [THEN] Verify that the first Item Variant Attribute.
        ItemVariantCard.ItemAttributesFactbox.First();
        ItemVariantCard.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[1].Name);
        ItemVariantCard.ItemAttributesFactbox.Value.AssertEquals(ExpectedAttributeValue);

        // [THEN] Verify that the second Item Variant Attribute.
        ItemVariantCard.ItemAttributesFactbox.Next();
        ItemVariantCard.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[2].Name);
        ItemVariantCard.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[2].Value);
        ItemVariantCard.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ModifyItemAttributeValueListHandler')]
    procedure ExistingAttributesRemainUnaffectedWhenNewItemAttributesAreAddedForMultiVariant()
    var
        Item: Record Item;
        ItemVariant: array[10] of Record "Item Variant";
        ItemAttribute: array[2] of Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        ExpectedAttributeValue: Text[250];
        i: Integer;
        VariantCount: Integer;
    begin
        // [SCENARIO 335313] Verify that when a new Item Attribute is added to the Item and
        // existing Item Variant Attribute Mappings remain unaffected after executing the UpdateItemVariantAttributeFromItem action for multiple Item Variants.
        Initialize();

        // [GIVEN] Create an Item with a text attribute.
        CreateItemWithTextAttribute(Item, ItemAttribute[1], ItemAttributeValue[1], LibraryUtility.GenerateGUID());

        // [GIVEN] Generate expected Item Attribute Value.
        ExpectedAttributeValue := LibraryUtility.GenerateGUID();
        VariantCount := LibraryRandom.RandInt(10);

        // [GIVEN] Create an Item Variant and Create a new Item Variant Attribute Value and remap value on the Item Variant.
        for i := 1 to VariantCount do begin
            LibraryInventory.CreateItemVariant(ItemVariant[i], Item."No.");
            CreateAndUpdateItemVariantAttributeValueMapping(ItemVariant[i], ItemAttribute[1].ID, ExpectedAttributeValue);
        end;

        // [GIVEN] Create a new Item Attribute and Item Attribute Value, and map them to the Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[2], ItemAttribute[2].Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[2], ItemAttribute[2].ID, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[2].ID, ItemAttributeValue[2].ID);

        // [WHEN] Update the Item Variant attributes from the Item.
        ItemAttributeManagement.UpdateItemVariantAttributeFromItem(Item."No.");

        // [THEN] Verify that the Item Variant Attribute Mappings.
        for i := 1 to VariantCount do
            VerifyItemVariantAttributes(ItemVariant[i], ItemAttribute, ItemAttributeValue, ExpectedAttributeValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ItemVariantAttributeIsDeletedWhenAssignedItemAttributeIsDeleted()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        // [SCENARIO 335313] Verify that Item Variant Attribute Mapping are deleted when an Item Attribute is deleted.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a new Item Attribute and Item Attribute Value, and map them to the Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Item Variant Attribute Value Mapping.
        LibraryInventory.CreateItemVariantAttributeValueMapping(ItemVariant."Item No.", ItemVariant.Code, ItemAttribute.ID, ItemAttributeValue.ID, 0, '');

        // [WHEN] Delete the Item Attribute.
        LibraryVariableStorage.Enqueue(DeleteUsedAttributeQst);
        ItemAttribute.Delete(true);

        // [THEN] Verify that the Item Variant Attribute Value Mapping is also deleted.
        ItemVariantAttributeValueMapping.SetRange("Item No.", Item."No.");
        ItemVariantAttributeValueMapping.SetRange("Variant Code", ItemVariant.Code);
        Assert.RecordIsEmpty(ItemVariantAttributeValueMapping);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ItemVariantAttributeIsUpdatedWhenAssignedItemAttributeIsRenamed()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariants: TestPage "Item Variants";
        RenameItemAttributeValue: Text[250];
    begin
        // [SCENARIO 335313] Verify that Item Variant Attribute Mapping are updated when an Item Attribute is renamed.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a new Item Attribute and Item Attribute Value, and map them to the Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Item Variant Attribute Value Mapping.
        LibraryInventory.CreateItemVariantAttributeValueMapping(ItemVariant."Item No.", ItemVariant.Code, ItemAttribute.ID, ItemAttributeValue.ID, 0, '');

        // [GIVEN] Generate new Item Attribute Value.
        RenameItemAttributeValue := LibraryUtility.GenerateGUID();

        // [GIVEN] Update the Item Attribute Value.
        LibraryVariableStorage.Enqueue(RenameUsedAttributeQst);
        LibraryVariableStorage.Enqueue(StrSubstNo(ReuseValueTranslationsQst, ItemAttribute.Name, RenameItemAttributeValue));
        ItemAttribute.Validate(Name, RenameItemAttributeValue);
        ItemAttribute.Modify();

        // [WHEN] Open Item Variant.
        ItemVariants.OpenEdit();
        ItemVariants.GoToRecord(ItemVariant);

        // [THEN] Verify that the Item Variant Attribute Value is updated.
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute.Name);
        ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue.Value);
        ItemVariants.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ItemVariantAttributeIsDeletedWhenAssignedItemAttributeValueIsDeleted()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        // [SCENARIO 335313] Verify that Item Variant Attribute Mapping are deleted when an Item Attribute Value is deleted.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a new Item Attribute and Item Attribute Value, and map them to the Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Item Variant Attribute Value Mapping.
        LibraryInventory.CreateItemVariantAttributeValueMapping(ItemVariant."Item No.", ItemVariant.Code, ItemAttribute.ID, ItemAttributeValue.ID, 0, '');

        // [WHEN] Delete the Item Attribute.
        LibraryVariableStorage.Enqueue(DeleteUsedAttributeValueQst);
        ItemAttributeValue.Delete(true);

        // [THEN] Verify that the Item Variant Attribute Value Mapping is also deleted.
        ItemVariantAttributeValueMapping.SetRange("Item No.", Item."No.");
        ItemVariantAttributeValueMapping.SetRange("Variant Code", ItemVariant.Code);
        Assert.RecordIsEmpty(ItemVariantAttributeValueMapping);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    procedure ItemVariantAttributeIsUpdatedWhenAssignedItemAttributeValueIsRenamed()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariants: TestPage "Item Variants";
    begin
        // [SCENARIO 335313] Verify that Item Variant Attribute Mapping are updated when an Item Attribute Value is renamed.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a new Item Attribute and Item Attribute Value, and map them to the Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Item Variant Attribute Value Mapping.
        LibraryInventory.CreateItemVariantAttributeValueMapping(ItemVariant."Item No.", ItemVariant.Code, ItemAttribute.ID, ItemAttributeValue.ID, 0, '');

        // [GIVEN] Update the Item Attribute Value.
        LibraryVariableStorage.Enqueue(RenameUsedAttributeValueQst);
        ItemAttributeValue.Validate(Value, LibraryUtility.GenerateGUID());
        ItemAttributeValue.Modify();

        // [WHEN] Open Item Variant.
        ItemVariants.OpenEdit();
        ItemVariants.GoToRecord(ItemVariant);

        // [THEN] Verify that the Item Variant Attribute Value is updated.
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute.Name);
        ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue.Value);
        ItemVariants.Close();
    end;

    [Test]
    procedure DateAndDecimalItemVariantAttributeIsInheritedFromItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: array[2] of Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
        ItemVariants: TestPage "Item Variants";
    begin
        // [SCENARIO 335313] Verify that Date and Decimal Item Variant Attributes are inherited from Item.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Decimal Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[1], ItemAttribute[1].Type::Decimal, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[1], ItemAttribute[1].ID, Format(LibraryRandom.RandDec(100, 2)));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[1].ID, ItemAttributeValue[1].ID);

        // [GIVEN] Create Date Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[2], ItemAttribute[2].Type::Date, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[2], ItemAttribute[2].ID, Format(Today()));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[2].ID, ItemAttributeValue[2].ID);

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [WHEN] Open Item Variant.
        ItemVariants.OpenEdit();
        ItemVariants.GoToRecord(ItemVariant);

        // [THEN] Verify that the Decimal Item Variant Attribute.
        ItemVariants.ItemAttributesFactbox.First();
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[1].Name);
        if ItemAttribute[1]."Unit of Measure" <> '' then
            ItemVariants.ItemAttributesFactbox.Value.AssertEquals(StrSubstNo('%1 %2', ItemAttributeValue[1].Value, Format(ItemAttribute[1]."Unit of Measure")))
        else
            ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[1].Value);

        // [THEN] Verify that the Date Item Variant Attribute.
        ItemVariants.ItemAttributesFactbox.Next();
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[2].Name);
        ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[2].Value);
        ItemVariants.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes,ModifyItemAttributeValueListHandler')]
    procedure DateItemVariantAttributeRemainsUnchangedAfterItemAttributeValueIsChanged()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        NewItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        ItemVariantCard: TestPage "Item Variant Card";
    begin
        // [SCENARIO 335313] Verify that Date Item Variant Attribute remains unchanged after Item Attribute Value is changed and "Update Variant Attributes" is executed.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Date Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Date, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(CalcDate('<+1D>', Today())));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a new Item Attribute Value.
        LibraryInventory.CreateItemAttributeValue(NewItemAttributeValue, ItemAttribute.ID, Format(Today()));
        LibraryVariableStorage.Enqueue(NewItemAttributeValue.Value);

        // [GIVEN] Invoke Attributes in Item Variant Card.
        ItemVariantCard.OpenEdit();
        ItemVariantCard.GoToRecord(ItemVariant);
        ItemVariantCard.Attributes.Invoke();

        // [GIVEN] Update Item Attribute Value on Item to a new date.
        CreateAndUpdateItemAttributeValueMapping(ItemAttributeValueMapping, ItemAttributeValue, ItemAttribute.ID, Item."No.", Format(CalcDate('<+2D>', Today())));

        // [WHEN] Update Item Variant attributes from Item.
        ItemAttributeManagement.UpdateItemVariantAttributeFromItem(Item."No.");

        // [THEN] Verify that the Item Variant Attribute Value Mapping remains the same.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute.ID);
        Assert.AreEqual(
            NewItemAttributeValue.ID,
            ItemVariantAttributeValueMapping."Item Attribute Value ID",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Item Attribute Value ID"), NewItemAttributeValue.ID, ItemVariantAttributeValueMapping.TableCaption()));
        Assert.AreEqual(
            0,
            ItemVariantAttributeValueMapping."Inherited-From Table ID",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Table ID"), 0, ItemVariantAttributeValueMapping.TableCaption()));
        Assert.AreEqual(
            '',
            ItemVariantAttributeValueMapping."Inherited-From Key Value",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Key Value"), '', ItemVariantAttributeValueMapping.TableCaption()));
    end;

    [Test]
    procedure ItemRenameKeepsItemVariantAttributeValueMapping()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: array[2] of Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
        ItemVariants: TestPage "Item Variants";
    begin
        // [SCENARIO 335313] Verify that the Item Variant Attribute Value Mappings are retained when the Item is renamed.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Decimal Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[1], ItemAttribute[1].Type::Decimal, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[1], ItemAttribute[1].ID, Format(LibraryRandom.RandDec(100, 2)));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[1].ID, ItemAttributeValue[1].ID);

        // [GIVEN] Create Date Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[2], ItemAttribute[2].Type::Date, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[2], ItemAttribute[2].ID, Format(Today()));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[2].ID, ItemAttributeValue[2].ID);

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Rename the Item.
        Item.Rename(LibraryUtility.GenerateRandomCode(Item.FieldNo("No."), Database::Item));

        // [GIVEN] Get the Item Variant.
        ItemVariant.Get(Item."No.", ItemVariant.Code);

        // [WHEN] Open Item Variant.
        ItemVariants.OpenEdit();
        ItemVariants.GoToRecord(ItemVariant);

        // [THEN] Verify that the Decimal Item Variant Attribute Value Mapping is retained.
        ItemVariants.ItemAttributesFactbox.First();
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[1].Name);
        if ItemAttribute[1]."Unit of Measure" <> '' then
            ItemVariants.ItemAttributesFactbox.Value.AssertEquals(StrSubstNo('%1 %2', ItemAttributeValue[1].Value, Format(ItemAttribute[1]."Unit of Measure")))
        else
            ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[1].Value);

        // [THEN] Verify that the Date Item Variant Attribute Value Mapping is retained.
        ItemVariants.ItemAttributesFactbox.Next();
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[2].Name);
        ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[2].Value);
        ItemVariants.Close();
    end;

    [Test]
    procedure ItemVariantRenameKeepsItemVariantAttributeValueMapping()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: array[2] of Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
        ItemVariants: TestPage "Item Variants";
    begin
        // [SCENARIO 335313] Verify that the Item Variant Attribute Value Mappings are retained when the Item Variant is renamed.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Decimal Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[1], ItemAttribute[1].Type::Decimal, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[1], ItemAttribute[1].ID, Format(LibraryRandom.RandDec(100, 2)));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[1].ID, ItemAttributeValue[1].ID);

        // [GIVEN] Create Date Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[2], ItemAttribute[2].Type::Date, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[2], ItemAttribute[2].ID, Format(Today()));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[2].ID, ItemAttributeValue[2].ID);

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Rename the Item Variant.
        ItemVariant.Rename(Item."No.", LibraryUtility.GenerateRandomCode(ItemVariant.FieldNo(Code), Database::"Item Variant"));

        // [WHEN] Open Item Variant.
        ItemVariants.OpenEdit();
        ItemVariants.GoToRecord(ItemVariant);

        // [THEN] Verify that the Decimal Item Variant Attribute Value Mapping is retained.
        ItemVariants.ItemAttributesFactbox.First();
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[1].Name);
        if ItemAttribute[1]."Unit of Measure" <> '' then
            ItemVariants.ItemAttributesFactbox.Value.AssertEquals(StrSubstNo('%1 %2', ItemAttributeValue[1].Value, Format(ItemAttribute[1]."Unit of Measure")))
        else
            ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[1].Value);

        // [THEN] Verify that the Date Item Variant Attribute Value Mapping is retained.
        ItemVariants.ItemAttributesFactbox.Next();
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[2].Name);
        ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[2].Value);
        ItemVariants.Close();
    end;

    [Test]
    procedure ItemVariantAttributeIsDeletedWhenAssignedItemVariantIsDeleted()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        // [SCENARIO 335313] Verify that Item Variant Attribute Mapping are deleted when an Item Variant is deleted.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a new Item Attribute and Item Attribute Value, and map them to the Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Item Variant Attribute Value Mapping.
        LibraryInventory.CreateItemVariantAttributeValueMapping(ItemVariant."Item No.", ItemVariant.Code, ItemAttribute.ID, ItemAttributeValue.ID, 0, '');

        // [WHEN] Delete the Item Variant.
        LibraryVariableStorage.Enqueue(DeleteUsedAttributeValueQst);
        ItemVariant.Delete(true);

        // [THEN] Verify that the Item Variant Attribute Value Mapping is also deleted.
        ItemVariantAttributeValueMapping.SetRange("Item No.", Item."No.");
        ItemVariantAttributeValueMapping.SetRange("Variant Code", ItemVariant.Code);
        Assert.RecordIsEmpty(ItemVariantAttributeValueMapping);
    end;

    [Test]
    procedure ItemVariantAttributeIsDeletedWhenAssignedItemIsDeleted()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        // [SCENARIO 335313] Verify that Item Variant Attribute Mapping are deleted when an Item is deleted.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a new Item Attribute and Item Attribute Value, and map them to the Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create Item Variant Attribute Value Mapping.
        LibraryInventory.CreateItemVariantAttributeValueMapping(ItemVariant."Item No.", ItemVariant.Code, ItemAttribute.ID, ItemAttributeValue.ID, 0, '');

        // [WHEN] Delete the Item.
        LibraryVariableStorage.Enqueue(DeleteUsedAttributeValueQst);
        Item.Delete(true);

        // [THEN] Verify that the Item Variant Attribute Value Mapping is also deleted.
        ItemVariantAttributeValueMapping.SetRange("Item No.", Item."No.");
        ItemVariantAttributeValueMapping.SetRange("Variant Code", ItemVariant.Code);
        Assert.RecordIsEmpty(ItemVariantAttributeValueMapping);
    end;

    [Test]
    procedure ItemAttributeValueIsNotDeletedIfMappedWithItem()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: array[2] of Record "Item Attribute";
        ItemAttributeValue: array[2] of Record "Item Attribute Value";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        // [SCENARIO 335313] Verify that the Item Attribute Value is not deleted when the Item Variant Attribute Value Mapping is deleted.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Decimal Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[1], ItemAttribute[1].Type::Decimal, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[1], ItemAttribute[1].ID, Format(LibraryRandom.RandDec(100, 2)));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[1].ID, ItemAttributeValue[1].ID);

        // [GIVEN] Create Date Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute[2], ItemAttribute[2].Type::Date, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue[2], ItemAttribute[2].ID, Format(Today()));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute[2].ID, ItemAttributeValue[2].ID);

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Find the Item Variant Attribute Value Mappings.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute[1].ID);

        // [WHEN] Delete the Item Variant Attribute Value Mapping.
        ItemVariantAttributeValueMapping.Delete(true);

        // [THEN] Verify that the Item Attribute Value still exists.
        ItemAttributeValue[1].SetRange("Attribute ID", ItemAttributeValue[1]."Attribute ID");
        ItemAttributeValue[1].SetRange(Id, ItemAttributeValue[1].ID);
        Assert.RecordIsNotEmpty(ItemAttributeValue[1]);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ItemAttributeValueIsNotDeletedIfAlreadyMappedWithItemAndItemVariant()
    var
        Item: array[2] of Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
    begin
        // [SCENARIO 335313] Verify that the Item Attribute Value is not deleted If already mapped with Item and Item Variant when the Item Variant Attribute Value Mapping is deleted.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item[1]);

        // [GIVEN] Create another Item.
        LibraryInventory.CreateItem(Item[2]);

        // [GIVEN] Create Decimal Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(LibraryRandom.RandDec(100, 2)));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item[1]."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Create Item Attribute Value Mapping for another Item.
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item[2]."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item[1]."No.");

        // [GIVEN] Find the Item Attribute Value Mapping.
        FindItemAttributeValueMapping(ItemAttributeValueMapping, Database::Item, Item[1]."No.", ItemAttribute.ID);

        // [WHEN] Delete the Item Attribute Value Mapping.
        ItemAttributeValueMapping.Delete(true);

        // [THEN] Verify that the Item Attribute Value still exists.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValue.SetRange(Id, ItemAttributeValue.ID);
        Assert.RecordIsNotEmpty(ItemAttributeValue);

        // [WHEN] Update the Item Variant attributes from the Item.
        ItemAttributeManagement.UpdateItemVariantAttributeFromItem(Item[1]."No.");

        // [THEN] Verify that the Item Attribute Value still exists.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValue.SetRange(Id, ItemAttributeValue.ID);
        Assert.RecordIsNotEmpty(ItemAttributeValue);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ItemAttributeValueIsDeletedIfNotMappedWithItemAndItemVariant()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeManagement: Codeunit "Item Attribute Management";
    begin
        // [SCENARIO 335313] Verify that the Item Attribute Value is deleted If not mapped with Item and Item Variant when the Item Attribute Value Mapping is deleted.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Decimal Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(LibraryRandom.RandDec(100, 2)));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Find the Item Attribute Value Mapping.
        FindItemAttributeValueMapping(ItemAttributeValueMapping, Database::Item, Item."No.", ItemAttribute.ID);

        // [WHEN] Delete the Item Attribute Value Mapping.
        ItemAttributeValueMapping.Delete(true);

        // [THEN] Verify that the Item Attribute Value still exists.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValue.SetRange(Id, ItemAttributeValue.ID);
        Assert.RecordIsNotEmpty(ItemAttributeValue);

        // [WHEN] Update the Item Variant attributes from the Item.
        ItemAttributeManagement.UpdateItemVariantAttributeFromItem(Item."No.");

        // [THEN] Verify that the Item Attribute Value is deleted.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValue.SetRange(Id, ItemAttributeValue.ID);
        Assert.RecordIsEmpty(ItemAttributeValue);
    end;

    [Test]
    procedure ItemAttributeValueIsDeletedIfItemVariantAttributeValueMappingIsDeleted()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        // [SCENARIO 335313] Verify that the Item Attribute Value is deleted if the Item Variant Attribute Value Mapping is deleted.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Decimal Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(LibraryRandom.RandDec(100, 2)));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Find the Item Attribute Value Mapping.
        FindItemAttributeValueMapping(ItemAttributeValueMapping, Database::Item, Item."No.", ItemAttribute.ID);

        // [WHEN] Delete the Item Attribute Value Mapping.
        ItemAttributeValueMapping.Delete(true);

        // [THEN] Verify that the Item Attribute Value still exists.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValue.SetRange(Id, ItemAttributeValue.ID);
        Assert.RecordIsNotEmpty(ItemAttributeValue);

        // [GIVEN] Find the Item Variant Attribute Value Mappings.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute.ID);

        // [WHEN] Delete the Item Variant Attribute Value Mapping.
        ItemVariantAttributeValueMapping.Delete(true);

        // [THEN] Verify that the Item Attribute Value is deleted.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValue.SetRange(Id, ItemAttributeValue.ID);
        Assert.RecordIsEmpty(ItemAttributeValue);
    end;

    [Test]
    [HandlerFunctions('ModifyItemAttributeValueListHandler')]
    procedure PreviousItemAttributeValueIsDeletedIfItemVariantAttributeValueIsChanged()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        // [SCENARIO 335313] Verify that the Item Attribute Value is deleted when the Item Variant Attribute Value is changed.
        Initialize();

        // [GIVEN] Create an Item.
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create Decimal Item Attribute and map to Item.
        LibraryInventory.CreateItemAttribute(ItemAttribute, ItemAttribute.Type::Decimal, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, ItemAttribute.ID, Format(LibraryRandom.RandDec(100, 2)));
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, Item."No.", ItemAttribute.ID, ItemAttributeValue.ID);

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Find the Item Attribute Value Mapping.
        FindItemAttributeValueMapping(ItemAttributeValueMapping, Database::Item, Item."No.", ItemAttribute.ID);

        // [WHEN] Delete the Item Attribute Value Mapping.
        ItemAttributeValueMapping.Delete(true);

        // [THEN] Verify that the Item Attribute Value still exists.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValue.SetRange(Id, ItemAttributeValue.ID);
        Assert.RecordIsNotEmpty(ItemAttributeValue);

        // [GIVEN] Find the Item Variant Attribute Value Mappings.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute.ID);

        // [WHEN] Create a new Item Variant Attribute Value and remap value on the Item Variant.
        CreateAndUpdateItemVariantAttributeValueMapping(ItemVariant, ItemAttribute.ID, Format(LibraryRandom.RandDec(100, 2)));

        // [THEN] Verify that the Item Attribute Value is deleted.
        ItemAttributeValue.SetRange("Attribute ID", ItemAttributeValue."Attribute ID");
        ItemAttributeValue.SetRange(Id, ItemAttributeValue.ID);
        Assert.RecordIsEmpty(ItemAttributeValue);
    end;

    [Test]
    procedure NoErrorOnRenameofItemVariantIfItemAttributesAreInheritedFromItem()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemVariant: Record "Item Variant";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        // [SCENARIO 619522] Cannot rename variant with item attributes: The Item Variant Attribute Value Mapping does not exist.
        Initialize();

        // [GIVEN] Create an Item with a text attribute.
        CreateItemWithTextAttribute(Item, ItemAttribute, ItemAttributeValue, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Verify that the Item Variant Attribute Value Mapping inherited from the Item.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute.ID);

        // [WHEN] Rename the Item Variant
        ItemVariant.Rename(Item."No.", LibraryUtility.GenerateRandomCode(ItemVariant.FieldNo(Code), DATABASE::"Item Variant"));

        // [THEN] Verify that the Item Variant Attribute Value Mapping inherited from the Item.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute.ID);
        Assert.RecordCount(ItemVariantAttributeValueMapping, 1);
        Assert.AreEqual(
            Database::Item,
            ItemVariantAttributeValueMapping."Inherited-From Table ID",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Table ID"), Database::Item, ItemVariantAttributeValueMapping.TableCaption()));
        Assert.AreEqual(
            Item."No.",
            ItemVariantAttributeValueMapping."Inherited-From Key Value",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Key Value"), Item."No.", ItemVariantAttributeValueMapping.TableCaption()));
    end;

    [Test]
    [HandlerFunctions('CopyItemPageHandler')]
    procedure CopyItemVariantAttributesValuesIfCopyItem()
    var
        Item: Record Item;
        TargetItem: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemVariant: Record "Item Variant";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
        CopyItemBuffer: Record "Copy Item Buffer";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
    begin
        // [SCENARIO 619488] Copy item actions doesn't copy Item Variant Attributes
        Initialize();

        // [GIVEN] Create an Item with a text attribute.
        CreateItemWithTextAttribute(Item, ItemAttribute, ItemAttributeValue, LibraryUtility.GenerateGUID());

        // [GIVEN] Create an Item Variant.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Verify that the Item Variant Attribute Value Mapping inherited from the Item.
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, Item."No.", ItemVariant.Code, ItemAttribute.ID);

        // [GIVEN] Copy the Item with Item Variants and Attributes option selected.
        CopyItemBuffer."Target Item No." := LibraryUtility.GenerateGUID();
        EnqueueValuesForCopyItemPageHandler(CopyItemBuffer);
        CopyItem(Item."No.");

        // [WHEN] Rename the Item Variant
        TargetItem.Get(CopyItemBuffer."Target Item No.");

        // [THEN] Verify that the Item Variant Attribute Value Mapping copie to New Item
        FindItemVariantAttributeValueMapping(ItemVariantAttributeValueMapping, TargetItem."No.", ItemVariant.Code, ItemAttribute.ID);
        Assert.RecordCount(ItemVariantAttributeValueMapping, 1);
        Assert.AreEqual(
            Database::Item,
            ItemVariantAttributeValueMapping."Inherited-From Table ID",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Table ID"), Database::Item, ItemVariantAttributeValueMapping.TableCaption()));
        Assert.AreEqual(
            TargetItem."No.",
            ItemVariantAttributeValueMapping."Inherited-From Key Value",
            StrSubstNo(ValueMustBeEqualErr, ItemVariantAttributeValueMapping.FieldCaption("Inherited-From Key Value"), Item."No.", ItemVariantAttributeValueMapping.TableCaption()));
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    procedure VerifyFactboxEmptyOnFirstLineOfVariantsPage()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariant: Record "Item Variant";
        ItemVariants: TestPage "Item Variants";
    begin
        // [SCENARIO 614482] Verify factbox is empty when opening variants page and clicking on first line.
        Initialize();

        // [GIVEN] Create an Item with attributes.
        CreateItemWithTextAttribute(Item, ItemAttribute, ItemAttributeValue, LibraryUtility.GenerateGUID());

        // [WHEN] Open Item Variants page.
        ItemVariants.OpenNew();

        // [THEN] Click on first new empty line.
        ItemVariants.First();

        // [THEN] Verify factbox is empty on first line.
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals('');
        ItemVariants.ItemAttributesFactbox.Value.AssertEquals('');

        // [WHEN] Create a new variant using library function.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [THEN] Close and reopen Item Variants page to navigate to the new variant.
        ItemVariants.Close();
        ItemVariants.OpenEdit();
        ItemVariants.GoToRecord(ItemVariant);

        // [THEN] Verify factbox should now show the inherited attributes.
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute.Name);
        ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue.Value);
        ItemVariants.Close();
    end;

    [Test]
    [HandlerFunctions('ModifyItemAttributeValueListHandler')]
    procedure VerifyEditActionOnItemVariantAttributeFactbox()
    var
        Item: Record Item;
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariant: Record "Item Variant";
        ItemVariants: TestPage "Item Variants";
        ChangedValue: Text;
    begin
        // [SCENARIO 619461] Verify Missing "Edit" action in the Item Attribute factbox in the Item Variant list
        Initialize();

        // [GIVEN] Create an Item with attributes.
        CreateItemWithTextAttribute(Item, ItemAttribute, ItemAttributeValue, LibraryUtility.GenerateGUID());

        // [GIVEN] Create a new variant using library function.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [WHEN] Open the Item Variant page and Edit the Item Attribut Factbox value.
        ChangedValue := LibraryRandom.RandText(50);
        ItemVariants.OpenEdit();
        ItemVariants.GoToRecord(ItemVariant);
        LibraryVariableStorage.Enqueue(ChangedValue);
        ItemVariants.ItemAttributesFactbox.EditVariant.Invoke();

        // [THEN] Verify factbox should now show the changed attributes value.
        ItemVariants.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute.Name);
        ItemVariants.ItemAttributesFactbox.Value.AssertEquals(ChangedValue);
        ItemVariants.Close();
    end;

    [Test]
    [HandlerFunctions('NewItemAttributeValueListHandler')]
    procedure AddNewBooleanAttributeOnItemVariantAttributeFactbox()
    var
        Item: Record Item;
        ItemAttribute, ItemAttributeBoolean : Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeBooleanValue: Record "Item Attribute Value";
        ItemVariant: Record "Item Variant";
        ItemVariants: TestPage "Item Variants";
    begin
        // [SCENARIO 624049] The Item Attribute Value Selection does not exist. Identification fields and values: Attribute Name='Assembly required'
        Initialize();

        // [GIVEN] Create an Item with attributes.
        CreateItemWithTextAttribute(Item, ItemAttribute, ItemAttributeValue, LibraryUtility.GenerateGUID());

        // [GIVEN] Create a new Attribute with Option as Yes, No
        LibraryInventory.CreateItemAttribute(ItemAttributeBoolean, ItemAttributeBoolean.Type::Option, '');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeBooleanValue, ItemAttributeBoolean.ID, 'Yes');
        LibraryInventory.CreateItemAttributeValue(ItemAttributeBooleanValue, ItemAttributeBoolean.ID, 'No');

        // [GIVEN] Create a new variant using library function.
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [WHEN] Open the Item Variant page and create new Item variant Attribute value.
        ItemVariants.OpenEdit();
        ItemVariants.GoToRecord(ItemVariant);
        LibraryVariableStorage.Enqueue(ItemAttributeBoolean.Name);
        LibraryVariableStorage.Enqueue(ItemAttributeBooleanValue.Value);
        ItemVariants.Attributes.Invoke();

        // [THEN] Verify No error should occcur
        // Hanlded in NewItemAttributeValueListHandler Page Handler
        ItemVariants.Close();
    end;

    local procedure Initialize()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariantAttrValueMapping: Record "Item Var. Attr. Value Mapping";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"SCM Item Variant Attributes");
        LibraryApplicationArea.EnableFoundationSetup();
        ItemAttribute.DeleteAll();
        ItemAttributeValue.DeleteAll();
        ItemAttributeValueMapping.DeleteAll();
        ItemVariantAttrValueMapping.DeleteAll();
        LibraryVariableStorage.Clear();
        LibraryNotificationMgt.DisableAllNotifications();
        LibraryVariableStorage.Clear();
        if IsInitialized then
            exit;

        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"SCM Item Variant Attributes");
        IsInitialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"SCM Item Variant Attributes");
    end;

    local procedure CreateItemWithTextAttribute(var NewItem: Record Item; var NewAttribute: Record "Item Attribute"; var NewValue: Record "Item Attribute Value"; ValueTxt: Text[250])
    begin
        LibraryInventory.CreateItem(NewItem);
        LibraryInventory.CreateItemAttribute(NewAttribute, NewAttribute.Type::Text, LibraryUtility.GenerateGUID());
        LibraryInventory.CreateItemAttributeValue(NewValue, NewAttribute.ID, ValueTxt);
        LibraryInventory.CreateItemAttributeValueMapping(Database::Item, NewItem."No.", NewAttribute.ID, NewValue.ID);
    end;

    local procedure FindItemVariantAttributeValueMapping(var ItemVariantAttributeMapping: Record "Item Var. Attr. Value Mapping"; ItemNo: Code[20]; VariantCode: Code[10]; AttributeID: Integer)
    begin
        ItemVariantAttributeMapping.SetRange("Item No.", ItemNo);
        ItemVariantAttributeMapping.SetRange("Variant Code", VariantCode);
        ItemVariantAttributeMapping.SetRange("Item Attribute ID", AttributeID);
        ItemVariantAttributeMapping.FindSet();
    end;

    local procedure FindItemAttributeValueMapping(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; TableID: Integer; KeyValue: Code[20]; AttributeID: Integer)
    begin
        ItemAttributeValueMapping.SetRange("Table ID", TableID);
        ItemAttributeValueMapping.SetRange("No.", KeyValue);
        ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeID);
        ItemAttributeValueMapping.FindSet();
    end;

    local procedure CreateAndUpdateItemAttributeValueMapping(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var NewItemAttributeValue: Record "Item Attribute Value"; AttributeID: Integer; ItemNo: Code[20]; NewValueTxt: Text[250])
    begin
        LibraryInventory.CreateItemAttributeValue(NewItemAttributeValue, AttributeID, NewValueTxt);

        ItemAttributeValueMapping.Get(Database::Item, ItemNo, AttributeID);
        ItemAttributeValueMapping."Item Attribute Value ID" := NewItemAttributeValue.ID;
        ItemAttributeValueMapping.Modify(true);
    end;

    local procedure CreateAndUpdateItemVariantAttributeValueMapping(ItemVariant: Record "Item Variant"; AttributeID: Integer; AttributeValue: Text[250])
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariantCard: TestPage "Item Variant Card";
    begin
        LibraryInventory.CreateItemAttributeValue(ItemAttributeValue, AttributeID, AttributeValue);
        LibraryVariableStorage.Enqueue(AttributeValue);

        ItemVariantCard.OpenEdit();
        ItemVariantCard.GoToRecord(ItemVariant);
        ItemVariantCard.Attributes.Invoke();
    end;

    local procedure VerifyItemVariantAttributes(ItemVariant: Record "Item Variant"; ItemAttribute: array[2] of Record "Item Attribute"; ItemAttributeValue: array[2] of Record "Item Attribute Value"; ExpectedAttributeValue: Text[250])
    var
        ItemVariantCard: TestPage "Item Variant Card";
    begin
        ItemVariantCard.OpenEdit();
        ItemVariantCard.GoToRecord(ItemVariant);

        ItemVariantCard.ItemAttributesFactbox.First();
        ItemVariantCard.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[1].Name);
        ItemVariantCard.ItemAttributesFactbox.Value.AssertEquals(ExpectedAttributeValue);

        ItemVariantCard.ItemAttributesFactbox.Next();
        ItemVariantCard.ItemAttributesFactbox.Attribute.AssertEquals(ItemAttribute[2].Name);
        ItemVariantCard.ItemAttributesFactbox.Value.AssertEquals(ItemAttributeValue[2].Value);
        ItemVariantCard.Close();
    end;

    local procedure EnqueueValuesForCopyItemPageHandler(CopyItemBuffer: Record "Copy Item Buffer")
    begin
        LibraryVariableStorage.Enqueue(CopyItemBuffer."Target Item No.");
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

    [ModalPageHandler]
    procedure ModifyItemAttributeValueListHandler(var ItemVariantAttributeValueEditor: TestPage "Item Variant Attribute Editor")
    var
        ItemAttributeValueVar: Variant;
        ItemAttributeValue: Text;
    begin
        LibraryVariableStorage.Dequeue(ItemAttributeValueVar);
        ItemAttributeValue := ItemAttributeValueVar;
        ItemVariantAttributeValueEditor.ItemVariantAttributeValueList.Value.SetValue(ItemAttributeValue);
        ItemVariantAttributeValueEditor.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure NewItemAttributeValueListHandler(var ItemVariantAttributeValueEditor: TestPage "Item Variant Attribute Editor")
    var
        ItemAttributeNameVar, ItemAttributeValueVar : Variant;
        ItemAttributeName, ItemAttributeValue : Text;
    begin
        LibraryVariableStorage.Dequeue(ItemAttributeNameVar);
        ItemAttributeName := ItemAttributeNameVar;
        LibraryVariableStorage.Dequeue(ItemAttributeValueVar);
        ItemAttributeValue := ItemAttributeValueVar;

        ItemVariantAttributeValueEditor.ItemVariantAttributeValueList.New();
        ItemVariantAttributeValueEditor.ItemVariantAttributeValueList."Attribute Name".SetValue(ItemAttributeName);
        ItemVariantAttributeValueEditor.ItemVariantAttributeValueList.Value.SetValue(ItemAttributeValue);
        ItemVariantAttributeValueEditor.OK().Invoke();
    end;

    [ConfirmHandler]
    procedure ConfirmHandler(Message: Text; var Reply: Boolean)
    var
        ExpectedQuestion: Text;
    begin
        ExpectedQuestion := LibraryVariableStorage.DequeueText();
        Assert.AreEqual(ExpectedQuestion, Message, '');
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure CopyItemPageHandler(var CopyItem: TestPage "Copy Item")
    begin
        CopyItem.TargetItemNo.SetValue(LibraryVariableStorage.DequeueText());
        CopyItem.GeneralItemInformation.SetValue(true);
        CopyItem.OK().Invoke();
    end;
}